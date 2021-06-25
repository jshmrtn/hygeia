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
  def call(conn, _opts) do
    conn
    |> get_session(:auth_tokens)
    |> case do
      nil -> conn
      {tokens, provider} -> handle_login(tokens, provider, conn)
    end
  end

  defp handle_login(
         tokens,
         provider,
         %Plug.Conn{request_path: request_path} = conn,
         refreshed \\ false
       ) do
    tokens
    |> upsert_user_with_tokens(provider)
    |> case do
      {:ok, %User{uuid: uuid, email: email, display_name: display_name, iam_sub: iam_sub} = user} ->
        Sentry.Context.set_user_context(%{
          uuid: uuid,
          email: email,
          display_name: display_name,
          iam_sub: iam_sub
        })

        {:ok,
         conn
         |> put_session(:auth, user)
         |> put_session(:auth_tokens, {tokens, provider})}

      {:error, reason} when refreshed ->
        {:error, reason}

      {:error, reason} when not refreshed ->
        case handle_refresh(tokens, provider) do
          {:ok, new_tokens} -> handle_login(new_tokens, provider, conn, true)
          {:error, :no_refresh_token} -> {:error, reason}
          {:error, new_reason} -> {:error, {reason, {:refresh, new_reason}}}
        end
    end
    |> case do
      {:ok, conn} ->
        conn

      {:error, reason} ->
        log = "Token Verify / Refresh Error: #{inspect(reason, pretty: true)}"
        Logger.warn(log)
        Sentry.capture_message(log)

        conn
        |> configure_session(drop: true)
        |> redirect(to: Helpers.auth_login_path(conn, :login, return_url: request_path))
        |> halt
    end
  end

  defp handle_refresh(tokens, provider) do
    with %{refresh: %{token: refresh_token}} when is_binary(refresh_token) <- tokens,
         {:ok, token_json} <- :oidcc.retrieve_fresh_token(refresh_token, provider),
         {:ok,
          %{
            "access_token" => access_token,
            "expires_in" => expires_in,
            "id_token" => id_token,
            "refresh_token" => refresh_token
          }} <- Jason.decode(token_json) do
      {:ok,
       tokens
       |> put_in([:access, :token], access_token)
       |> put_in([:access, :expires], expires_in)
       |> put_in([:id, :token], id_token)
       |> put_in([:refresh, :token], refresh_token)}
    else
      %{refresh: %{token: :none}} -> {:error, :no_refresh_token}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec upsert_user_with_tokens(tokens :: map, provider :: String.t()) ::
          {:ok, User.t()} | {:error, term}
  def upsert_user_with_tokens(tokens, provider) do
    with {:ok, user_info} <- :oidcc.retrieve_user_info(tokens, provider),
         {:ok, user} <- upsert_user(user_info),
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
