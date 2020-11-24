defmodule HygeiaWeb.AuthController do
  use HygeiaWeb, :controller

  alias HygeiaWeb.Plug.CheckAndRefreshAuthentication

  require Logger

  plug Ueberauth

  @spec delete(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()
  def delete(conn, _params) do
    {:ok, %{end_session_endpoint: end_session_endpoint}} =
      :oidcc.get_openid_provider_info("zitadel")

    %{query: query} = end_session_uri = URI.parse(end_session_endpoint)

    query =
      query
      |> Kernel.||("")
      |> URI.decode_query()
      |> Map.put("post_logout_redirect_uri", Routes.home_url(conn, :index))
      |> URI.encode_query()

    after_logout_url = URI.to_string(%{end_session_uri | query: query})

    conn
    |> put_flash(:info, gettext("You have been logged out!"))
    |> configure_session(drop: true)
    |> redirect(external: after_logout_url)
  end

  @spec callback(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.warn("""
    Login failed, reason:
    #{inspect(fails, pretty: true)}
    """)

    conn
    |> put_status(:unauthorized)
    |> render("oidc_error.html", reason: fails)
  end

  def callback(
        %{
          assigns: %{
            ueberauth_auth: %Ueberauth.Auth{
              credentials: %{
                other: %{
                  provider: provider
                }
              },
              extra: %Ueberauth.Auth.Extra{
                raw_info: %{
                  tokens: tokens
                }
              }
            }
          }
        } = conn,
        _params
      ) do
    tokens
    |> CheckAndRefreshAuthentication.upsert_user_with_tokens(provider)
    |> case do
      {:ok, user} ->
        conn
        |> put_flash(:info, gettext("Successfully authenticated."))
        |> put_session(:auth, user)
        |> put_session(:auth_tokens, {tokens, provider})
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.warn("""
        Login failed, reason:
        #{inspect(reason, pretty: true)}
        """)

        conn
        |> put_status(:unauthorized)
        |> render("oidc_error.html", reason: reason)
    end
  end
end
