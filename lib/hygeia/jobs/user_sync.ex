defmodule Hygeia.Jobs.UserSync do
  @moduledoc """
  Sync IAM
  """

  use GenServer

  alias Ecto.Multi
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User
  alias Zitadel.Management.V1.ListUserGrantRequest
  alias Zitadel.Management.V1.ListUserGrantResponse
  alias Zitadel.Management.V1.ManagementService.Stub
  alias Zitadel.User.V1.UserGrant
  alias Zitadel.User.V1.UserGrantProjectIDQuery
  alias Zitadel.User.V1.UserGrantQuery
  alias Zitadel.User.V1.UserGrantWithGrantedQuery
  alias Zitadel.V1.ListQuery

  alias HygeiaIam.ServiceUserToken

  require Logger

  @limit 250

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.minutes(5)
  end

  @grpc_server "hygeia-aprced.zitadel.cloud:443"

  defstruct [:channel, :user_sync_token_server_name]

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:user_sync_token_server_name]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    Versioning.put_originator(:noone)
    Versioning.put_origin(:user_sync_job)

    @grpc_server
    |> GRPC.Stub.connect(cred: %{ssl: []}, metadata: %{})
    |> case do
      {:ok, channel} ->
        Process.send_after(self(), :start_interval, :rand.uniform(@default_refresh_interval_ms))

        {:ok,
         %__MODULE__{
           channel: channel,
           user_sync_token_server_name: Keyword.fetch!(opts, :user_sync_token_server_name)
         }}

      {:error, reason} ->
        {:stop, {:error, reason}}
    end
  end

  @impl GenServer
  def handle_info(:start_interval, state) do
    :timer.send_interval(@default_refresh_interval_ms, :sync)
    send(self(), :sync)

    {:noreply, state}
  end

  def handle_info(
        :sync,
        %__MODULE__{channel: channel, user_sync_token_server_name: user_sync_token_server_name} =
          state
      ) do
    case ServiceUserToken.get_access_token(user_sync_token_server_name) do
      {:ok, token} ->
        sync(channel, token)

      {:error, reason} ->
        Logger.error("""
        Skipping IAM Sync because no access token could be obtained:
        #{inspect(reason, pretty: true)}
        """)
    end

    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  defp sync(channel, access_token) do
    tenants = Map.new(TenantContext.list_tenants(), &{&1.iam_domain, &1})

    db_users =
      UserContext.list_users()
      |> Repo.preload(:grants)
      |> Map.new(&{&1.iam_sub, {&1, []}})

    {:ok, results} =
      channel
      |> list_users(access_token)
      |> Enum.reduce(db_users, fn %UserGrant{user_id: sub} = grant, acc ->
        Map.update(acc, sub, {nil, [grant]}, &{elem(&1, 0), [grant | elem(&1, 1)]})
      end)
      |> Map.values()
      |> Enum.reduce(Multi.new(), &merge(elem(&1, 0), elem(&1, 1), &2, tenants))
      |> Versioning.authenticate_multi()
      |> Repo.transaction()

    stats =
      results
      |> Map.keys()
      |> Enum.reduce(%{insert: 0, update: 0}, fn
        :set_versioning_variables, acc ->
          acc

        {type, _sub}, acc ->
          Map.update!(acc, type, &(&1 + 1))
      end)

    Logger.info("Synced Users with IAM (#{inspect(stats)}")
  end

  defp merge(nil, [%UserGrant{user_id: sub} | _other_grants] = grants, multi, tenants) do
    Logger.debug("Creating user #{sub}")

    Multi.insert(
      multi,
      {:insert, sub},
      UserContext.change_user(%User{}, to_user_attrs(grants, tenants))
    )
  end

  defp merge(
         %User{iam_sub: sub} = user,
         grants,
         multi,
         tenants
       ) do
    attrs = to_user_attrs(grants, tenants)

    # Checking empty grants list because of not deleted user with no grants
    #   email != nil and display_name != anonymous coming from access_token
    if (Enum.empty?(user.grants) and Enum.empty?(attrs.grants)) or
         UserContext.user_identical_after_update?(user, attrs) do
      Logger.debug("No changes for user #{sub}")

      multi
    else
      Logger.debug("Updating user #{sub}")

      changeset = UserContext.change_user(user, attrs)
      Ecto.Multi.update(multi, {:update, sub}, changeset)
    end
  end

  defp to_user_attrs(
         [%UserGrant{user_id: sub, email: email, display_name: display_name} | _other_grants] =
           iam_grants,
         tenants
       ) do
    %{
      iam_sub: sub,
      email: email,
      display_name: display_name,
      grants: to_grant_attrs(iam_grants, tenants)
    }
  end

  defp to_user_attrs([] = _iam_grants, _tenants), do: %{grants: []}

  defp to_grant_attrs(iam_grants, tenants) do
    iam_grants
    |> Enum.flat_map(fn %UserGrant{role_keys: roles, org_domain: domain} ->
      tenants
      |> Map.fetch(domain)
      |> case do
        :error ->
          Logger.warn("Tenant for domain #{domain} does not exist, skipping grants.")
          []

        {:ok, tenant} ->
          Enum.map(roles, &{&1, tenant})
      end
    end)
    |> Enum.map(
      &%{
        role: elem(&1, 0),
        tenant_uuid: elem(&1, 1).uuid
      }
    )
  end

  defp list_users(channel, access_token) do
    Stream.resource(
      fn -> 0 end,
      fn
        false ->
          {:halt, nil}

        offset ->
          channel
          |> load_page(access_token, offset)
          |> case do
            {:ok, %ListUserGrantResponse{result: []}} -> {:halt, offset}
            {:ok, %ListUserGrantResponse{result: grants}} -> {grants, offset + length(grants)}
          end
      end,
      fn _acc -> :ok end
    )
  end

  defp load_page(channel, access_token, offset) do
    Stub.list_user_grants(
      channel,
      ListUserGrantRequest.new(
        query:
          ListQuery.new(
            offset: offset,
            limit: @limit
          ),
        queries: [
          UserGrantQuery.new(
            query:
              {:project_id_query, UserGrantProjectIDQuery.new(project_id: HygeiaIam.project_id())}
          ),
          UserGrantQuery.new(
            query: {:with_granted_query, UserGrantWithGrantedQuery.new(with_granted: true)}
          )
        ]
      ),
      metadata: %{
        "authorization" => "Bearer #{access_token}",
        "x-zitadel-orgid" => HygeiaIam.organisation_id()
      }
    )
  end
end
