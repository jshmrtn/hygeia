defmodule HygeiaWeb.HelpLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def handle_info(_other, socket), do: {:noreply, socket}
end
