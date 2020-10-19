defmodule HygeiaWeb.Modal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.LivePatch

  slot footer

  prop return_to, :string, required: false, default: "#"
  prop title, :string, default: ""

  @impl Phoenix.LiveComponent
  def handle_event("close", _uri, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
