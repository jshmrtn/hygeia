defmodule HygeiaWeb.LocaleController do
  use HygeiaWeb, :controller

  alias Cldr.Plug.SetLocale

  @spec set_locale(Plug.Conn.t(), map) :: Plug.Conn.t()
  def set_locale(conn, %{"locale" => locale, "redirect_uri" => redirect_uri}) do
    locale =
      case HygeiaCldr.validate_locale(locale) do
        {:ok, locale} -> locale
        {:error, _reason} -> HygeiaCldr.default_locale()
      end

    HygeiaCldr.put_locale(locale)
    Gettext.put_locale(HygeiaGettext, locale.gettext_locale_name)

    conn
    |> put_session(SetLocale.session_key(), locale.canonical_locale_name)
    |> maybe_set_language_warning(locale.gettext_locale_name)
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
