defmodule HygeiaWeb.AuthController do
  use HygeiaWeb, :controller

  alias Hygeia.Helpers.Versioning
  alias Hygeia.UserContext

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
      |> Map.put("post_logout_redirect_uri", Routes.page_url(conn, :index))
      |> URI.encode_query()

    after_logout_url = URI.to_string(%{end_session_uri | query: query})

    conn
    |> put_flash(:info, gettext("You have been logged out!"))
    |> configure_session(drop: true)
    |> redirect(external: after_logout_url)
  end

  @spec callback(conn :: Plug.Conn.t(), params :: %{String.t() => String.t()}) :: Plug.Conn.t()

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
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
    |> :oidcc.retrieve_user_info(provider)
    |> case do
      {:ok, user_info} ->
        Versioning.put_origin(:web)
        Versioning.put_originator(:noone)

        user = upsert_user(user_info)

        conn
        |> put_flash(:info, gettext("Successfully authenticated."))
        |> put_session(:auth, user)
        |> configure_session(renew: true)
        |> redirect(to: "/")

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> render("oidc_error.html", reason: reason)
    end
  end

  defp upsert_user(%{email: email, name: name, sub: sub}) do
    %{
      email: email,
      display_name: name,
      iam_sub: sub
    }
    |> UserContext.create_user()
    |> case do
      {:ok, user} ->
        user

      {:error,
       %Ecto.Changeset{
         errors: [
           iam_sub: {_message, [constraint: :unique, constraint_name: "users_iam_sub_index"]}
         ]
       }} ->
        {:ok, user} =
          sub
          |> UserContext.get_user_by_sub!()
          |> UserContext.update_user(%{
            email: email,
            display_name: name
          })

        user
    end
  end
end
