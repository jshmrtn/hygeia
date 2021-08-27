defmodule HygeiaWeb.LocaleController do
  use HygeiaWeb, :controller

  alias Cldr.Plug.SetLocale

  @spec set_locale(Plug.Conn.t(), map) :: Plug.Conn.t()
  def set_locale(conn, %{"locale" => locale, "redirect_uri" => redirect_uri}) do
    locale =
      if HygeiaCldr.known_gettext_locale_name?(locale),
        do: locale,
        else: HygeiaCldr.default_locale()

    conn
    |> put_session(SetLocale.session_key(), locale)
    |> redirect(external: redirect_uri)
  end
end
