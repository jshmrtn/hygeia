defmodule HygeiaWeb.SystemMessagesBanner do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  data hidden_message_ids, :list, default: nil

  @impl Phoenix.LiveComponent
  def handle_event("hide_alerts", %{"alertIds" => hidden_message_ids}, socket) do
    {:noreply, assign(socket, hidden_message_ids: hidden_message_ids)}
  end

  defp filtered_system_messages(auth, hidden_message_ids) do
    Enum.reject(
      Hygeia.SystemMessageContext.list_active_system_messages(auth),
      fn {id, _msg} -> id in hidden_message_ids end
    )
  end
end
