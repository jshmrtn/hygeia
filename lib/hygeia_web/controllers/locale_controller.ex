defmodule HygeiaWeb.LocaleController do
  use HygeiaWeb, :controller

  alias Cldr.Plug.SetLocale

  @spec set_locale(Plug.Conn.t(), map) :: Plug.Conn.t()
  def set_locale(conn, %{"locale" => locale, "redirect_uri" => redirect_uri}) do
    locale =
      if HygeiaCldr.known_gettext_locale_name?(locale),
        do: locale,
        else: HygeiaCldr.default_locale()

    HygeiaCldr.put_locale(locale)
    Gettext.put_locale(HygeiaGettext, locale)

    conn
    |> put_session(SetLocale.session_key(), locale)
    |> maybe_set_language_warning(locale)
    |> redirect(external: redirect_uri)
  end

  defp maybe_set_language_warning(conn, locale) do
    if HygeiaGettext.is_fuzzy_language?(locale) do
      put_flash(conn, :warning, gettext("The displayed language was translated mechanically."))
    else
      conn
    end
  end
end
