defmodule HygeiaWeb.HelpLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, page_title: gettext("Help"))
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_other, socket), do: {:noreply, socket}
end
