defmodule HygeiaWeb.HelpButton do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.NotificationContext
  alias Hygeia.UserContext

  prop case, :map, required: true

  @impl Phoenix.LiveComponent
  def handle_event("send_help_request", _params, socket) do
    # TODO: Start Self-Service only if tracer is assigned!
    user = UserContext.get_user!(socket.assigns.case.tracer_uuid)

    NotificationContext.create_notification(user, %{
      body: %{
        uuid: Ecto.UUID.generate(),
        __type__: :self_service_help_request,
        case_uuid: socket.assigns.case.uuid
      }
    })

    {:noreply, socket}
  end
end
