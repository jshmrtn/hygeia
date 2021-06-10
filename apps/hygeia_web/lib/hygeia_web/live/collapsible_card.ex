defmodule HygeiaWeb.CollapsibleCard do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop title, :string, default: ""

  data collapsed, :boolean, default: false

  slot default, required: true

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, collapsed: !socket.assigns.collapsed)}
  end
end
