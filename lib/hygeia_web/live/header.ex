defmodule HygeiaWeb.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop auth, :map, from_context: {HygeiaWeb, :auth}
  prop logged_in, :boolean, from_context: {HygeiaWeb, :logged_in}
  prop uri, :string, from_context: {HygeiaWeb, :uri}

  defp get_current_language do
    locale = HygeiaCldr.get_locale()
    {:ok, lang} = HygeiaCldr.Language.to_string(locale.language, locale: locale)
    lang
  end
end
