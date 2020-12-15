defmodule HygeiaWeb.Plug.CheckAndRefreshAuthentication do
  @moduledoc """
  Put Authentication into Conn
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller

  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias Hygeia.UserContext.Grant.Role
  alias Hygeia.UserContext.User
  alias HygeiaWeb.Router.Helpers

  require Logger

  @impl Plug
  def init(_opts) do
    nil
  end

  @impl Plug
  def call(%Plug.Conn{request_path: request_path} = conn, _opts) do
    conn
    |> get_session(:auth_tokens)
    |> case do
      nil ->
        conn

      {tokens, provider} ->
        tokens
        |> upsert_user_with_tokens(provider)
        |> case do
          {:ok, user} ->
            put_session(conn, :auth, user)

          {:error, _reason} ->
            conn
            |> configure_session(drop: true)
            |> redirect(to: Helpers.auth_path(conn, :request, "oidc", return_url: request_path))
            |> halt

            # TODO: Refresh token if expired as soon as Zitadel is ready
        end
    end
  end

  @spec upsert_user_with_tokens(tokens :: map, provider :: String.t()) ::
          {:ok, User.t()} | {:error, term}
  def upsert_user_with_tokens(tokens, provider) do
    with :ok <- Logger.info("Retrieve UserInfo Start"),
         {:ok, user_info} <- :oidcc.retrieve_user_info(tokens, provider),
         :ok <- Logger.info("Retrieve UserInfo End"),
         :ok <- Logger.info("Upsert User Start"),
         {:ok, user} <- upsert_user(user_info),
         :ok <- Logger.info("Upsert User End"),
         user <- Repo.preload(user, :grants) do
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    # return_json_info({ok, #{status := 200, body := Data}}) ->
    # with {:error, :timeout}
    FunctionClauseError -> {:error, :timeout}
  end

  defp upsert_user(
         %{
           email: email,
           name: name,
           sub: sub
         } = attrs
       ) do
    tenants = Map.new(TenantContext.list_tenants(), &{&1.iam_domain, &1})

    grants =
      attrs
      |> Map.get(:"urn:zitadel:iam:org:project:roles", %{})
      |> Enum.flat_map(fn {role, grants} ->
        grants
        |> Map.values()
        |> Enum.map(&{role, tenants[&1]})
      end)
      |> Enum.reject(&match?({_role, nil}, &1))
      |> Enum.map(fn {role, tenant} -> %{role: role, tenant_uuid: tenant.uuid} end)
      |> Enum.filter(&Role.valid_value?(&1.role))

    Versioning.put_origin(:web)
    Versioning.put_originator(:noone)

    UserContext.upsert_user(%{
      email: email,
      display_name: name,
      iam_sub: sub,
      grants: grants
    })
  end
end
