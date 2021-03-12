defmodule HygeiaWeb.SystemMessageLive.Banner do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  data messages, :list, default: []
  data hidden_message_ids, :list, default: []

  @impl Phoenix.LiveComponent
  def mount(socket) do
    IO.inspect(get_auth(socket))

    {:ok, socket |> assign(hidden_message_ids: []) |> filter_system_messages}
  end

  @impl Phoenix.LiveComponent
  def handle_event("hide_alerts", %{"alertIds" => hidden_message_ids}, socket) do
    IO.inspect(hidden_message_ids)

    socket |> assign(hidden_message_ids: hidden_message_ids) |> filter_system_messages
  end

  defp filter_system_messages(socket) do
    system_messages =
      Enum.filter(
        Hygeia.SystemMessageContext.list_active_system_messages(get_auth(socket)),
        fn {id, _msg} -> not (id in socket.assigns.hidden_message_ids) end
      )

    assign(socket, messages: system_messages)
  end
end
