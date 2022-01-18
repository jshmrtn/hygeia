defmodule HygeiaWeb.Init.Locale do
  @moduledoc """
  Load Locale on mount
  """

  import Cldr.Plug.SetLocale, only: [session_key: 0]

  @spec on_mount(
          context :: atom(),
          Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
          session :: map,
          socket :: Phoenix.LiveView.Socket.t()
        ) :: {:cont | :halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    unless is_nil(session[session_key()]) do
      HygeiaCldr.put_locale(session[session_key()])
      Gettext.put_locale(HygeiaCldr.get_locale().gettext_locale_name || "de")

      Sentry.Context.set_tags_context(%{locale: session[session_key()]})
    end

    {:cont, socket}
  end
end
