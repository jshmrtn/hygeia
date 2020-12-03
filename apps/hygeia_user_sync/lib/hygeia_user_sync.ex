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
  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

  alias HygeiaIam.ServiceUserToken

  require Logger

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

  defp sync(channel, access_token) do
    {:ok, %UserGrantSearchResponse{result: grants}} =
      Stub.search_user_grants(
        channel,
        UserGrantSearchRequest.new(
          limit: 1000,
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

    db_users = UserContext.list_users()

    for %UserGrantView{
          email: email,
          user_id: sub,
          display_name: display_name,
          role_keys: roles
        } <- grants do
      roles = Enum.map(roles, &String.to_existing_atom/1)

      db_users
      |> Enum.find(&match?(%User{iam_sub: ^sub}, &1))
      |> case do
        nil ->
          create_user(%{
            email: email,
            display_name: display_name,
            iam_sub: sub,
            roles: roles
          })

        %User{email: ^email, display_name: ^display_name, roles: ^roles} ->
          :ok

        user ->
          update_user(user, %{
            email: email,
            display_name: display_name,
            roles: roles
          })
      end
    end

    for %User{iam_sub: sub} = user <- db_users do
      grants
      |> Enum.find(&match?(%UserGrantView{user_id: ^sub}, &1))
      |> case do
        nil ->
          delete_user(user)

        _grant ->
          :ok
      end
    end
  end

  defp create_user(attrs) do
    attrs
    |> UserContext.create_user()
    |> case do
      {:ok, user} ->
        Logger.info("Created User #{user.email}", user: user)

        :ok

      {:error, reason} ->
        Logger.warn(
          """
          Could not create user:

          #{inspect(reason, pretty: true)}
          """,
          reason: reason
        )

        {:error, reason}
    end
  end

  defp update_user(user, attrs) do
    user
    |> UserContext.update_user(attrs)
    |> case do
      {:ok, user} ->
        Logger.info("Updated User #{user.email}", user: user)

        :ok

      {:error, reason} ->
        Logger.warn(
          """
          Could not update user #{user.email}:

          #{inspect(reason, pretty: true)}
          """,
          reason: reason
        )

        {:error, reason}
    end
  end

  defp delete_user(user) do
    user
    |> UserContext.delete_user()
    |> case do
      {:ok, user} ->
        Logger.info("Deleted User #{user.email}", user: user)

        :ok

      {:error, reason} ->
        Logger.warn(
          """
          Could not delete user #{user.email}:

          #{inspect(reason, pretty: true)}
          """,
          reason: reason
        )

        {:error, reason}
    end
  end
end
