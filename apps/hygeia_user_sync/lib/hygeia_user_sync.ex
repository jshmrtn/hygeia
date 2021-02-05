defmodule HygeiaUserSync do
  @moduledoc """
  Sync IAM
  """

  use GenServer

  alias Caos.Zitadel.Management.Api.V1.ManagementService.Stub
  alias Caos.Zitadel.Management.Api.V1.SearchMethod
  alias Caos.Zitadel.Management.Api.V1.UserGrantSearchKey
  alias Caos.Zitadel.Management.Api.V1.UserGrantSearchQuery
  alias Caos.Zitadel.Management.Api.V1.UserGrantSearchRequest
  alias Caos.Zitadel.Management.Api.V1.UserGrantSearchResponse
  alias Caos.Zitadel.Management.Api.V1.UserGrantView
  alias Ecto.Multi
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  alias HygeiaIam.ServiceUserToken

  require Logger

  @limit 250

  case Mix.env() do
    :dev -> @default_refresh_interval_ms :timer.seconds(30)
    _env -> @default_refresh_interval_ms :timer.minutes(5)
  end

  @grpc_server "api.zitadel.ch:443"

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
        send(self(), :sync)

        :timer.send_interval(@default_refresh_interval_ms, :sync)

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
  def handle_info(
        :sync,
        %__MODULE__{channel: channel, user_sync_token_server_name: user_sync_token_server_name} =
          state
      ) do
    sync(channel, ServiceUserToken.get_access_token(user_sync_token_server_name))

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
      |> Enum.reduce(db_users, fn %UserGrantView{user_id: sub} = grant, acc ->
        Map.update(acc, sub, {nil, [grant]}, &{elem(&1, 0), [grant | elem(&1, 1)]})
      end)
      |> Map.values()
      |> Enum.reduce(Multi.new(), &merge(elem(&1, 0), elem(&1, 1), &2, tenants))
      |> Repo.transaction()

    stats =
      results
      |> Map.keys()
      |> Enum.reduce(%{insert: 0, update: 0}, fn {type, _sub}, acc ->
        Map.update!(acc, type, &(&1 + 1))
      end)

    Logger.info("Synced Users with IAM (#{inspect(stats)}")
  end

  defp merge(nil, [%UserGrantView{user_id: sub} | _other_grants] = grants, multi, tenants) do
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

    if UserContext.user_identical_after_update?(user, attrs) do
      Logger.debug("No changes for user #{sub}")

      multi
    else
      Logger.debug("Updating user #{sub}")

      changeset = UserContext.change_user(user, attrs)
      Ecto.Multi.update(multi, {:update, sub}, changeset)
    end
  end

  defp to_user_attrs(
         [%UserGrantView{user_id: sub, email: email, display_name: display_name} | _other_grants] =
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
    |> Enum.flat_map(fn %UserGrantView{role_keys: roles, org_domain: domain} ->
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
            {:ok, %UserGrantSearchResponse{result: []}} -> {:halt, offset}
            {:ok, %UserGrantSearchResponse{result: grants}} -> {grants, offset + length(grants)}
          end
      end,
      fn _acc -> :ok end
    )
  end

  defp load_page(channel, access_token, offset) do
    Stub.search_user_grants(
      channel,
      UserGrantSearchRequest.new(
        offset: offset,
        limit: @limit,
        queries: [
          UserGrantSearchQuery.new(
            key: UserGrantSearchKey.value(:USERGRANTSEARCHKEY_PROJECT_ID),
            method: SearchMethod.value(:SEARCHMETHOD_EQUALS),
            value: HygeiaIam.project_id()
          ),
          UserGrantSearchQuery.new(
            key: UserGrantSearchKey.value(:USERGRANTSEARCHKEY_WITH_GRANTED),
            method: SearchMethod.value(:SEARCHMETHOD_EQUALS),
            value: "true"
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
