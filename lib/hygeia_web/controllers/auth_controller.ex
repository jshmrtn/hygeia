defmodule HygeiaWeb.AuthController do
  use HygeiaWeb, :controller

  alias Hygeia.CaseContext
  alias HygeiaWeb.Plug.CheckAndRefreshAuthentication
  alias Phoenix.Token

  require Logger

  @spec delete(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn =
      conn
      |> put_flash(:info, gettext("You have been logged out!"))
      |> configure_session(drop: true)

    case get_session(conn, :auth_tokens) do
      nil ->
        redirect(conn, to: "/")

      _tokens ->
        end_session_endpoint =
          case :oidcc.get_openid_provider_info("zitadel") do
            {:ok, %{end_session_endpoint: end_session_endpoint}} -> end_session_endpoint
            {:ok, %{"end_session_endpoint" => end_session_endpoint}} -> end_session_endpoint
          end

        %{query: query} = end_session_uri = URI.parse(end_session_endpoint)

        query =
          query
          |> Kernel.||("")
          |> URI.decode_query()
          |> Map.put("post_logout_redirect_uri", Routes.home_index_url(conn, :index))
          |> URI.encode_query()

        after_logout_url = URI.to_string(%{end_session_uri | query: query})

        redirect(conn, external: after_logout_url)
    end
  end

  @spec request(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()
  def request(conn, %{"provider" => "zitadel"} = params) do
    session = HygeiaIam.generate_session_info("zitadel", params["return_url"])

    redirect_uri = HygeiaIam.generate_redirect_url!(session)

    conn
    |> put_session(
      __MODULE__,
      HygeiaIam.clean_sessions([session | get_session(conn, __MODULE__) || []])
    )
    |> redirect(external: redirect_uri)
  end

  def request(conn, %{"provider" => "person", "uuid" => signed_uuid} = params) do
    case Token.verify(conn, "person auth", signed_uuid, max_age: 30) do
      {:ok, uuid} ->
        conn
        |> put_flash(:info, gettext("Successfully authenticated."))
        |> put_session(:auth, CaseContext.get_person!(uuid))
        |> redirect(to: params["return_url"] || "/")

      {:error, reason} when reason in [:invalid, :expired] ->
        conn
        |> put_flash(:info, gettext("Error while authenticating."))
        |> redirect(to: "/")
    end
  end

  @spec callback(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()
  def callback(conn, params) do
    tokens =
      %{state: state, provider: provider, remaining_sessions: remaining_sessions} =
      conn
      |> get_session(__MODULE__)
      |> case do
        nil -> []
        list when is_list(list) -> list
      end
      |> HygeiaIam.retrieve_and_validate_token!(params)

    tokens
    |> CheckAndRefreshAuthentication.upsert_user_with_tokens(provider)
    |> case do
      {:ok, user} ->
        Logger.info("Upsert Successful")

        conn
        |> put_flash(:info, gettext("Successfully authenticated."))
        |> put_session(:auth, user)
        |> put_session(:auth_tokens, {tokens, provider})
        |> put_session(__MODULE__, remaining_sessions)
        |> configure_session(renew: true)
        |> redirect(
          to:
            case state do
              nil -> "/"
              other -> other
            end
        )

      {:error, reason} ->
        Logger.warn("""
        Login failed, reason:
        #{inspect(reason, pretty: true)}
        """)

        conn
        |> put_status(:unauthorized)
        |> render("oidc_error.html", reason: reason)
    end
  rescue
    e in HygeiaIam.OidcError ->
      Logger.warn("""
      Login failed, reason:
      #{inspect(e, pretty: true)}
      """)

      conn
      |> put_status(:unauthorized)
      |> render("oidc_error.html", reason: e)
  end
end
