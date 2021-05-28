defmodule HygeiaWeb.Notification.Tray do
  @moduledoc false

  use HygeiaWeb, :surface_view_bare

  alias Hygeia.NotificationContext
  alias Hygeia.NotificationContext.Notification
  alias Hygeia.UserContext.User

  data notifications, :list, default: []
  data now, :map, default: nil

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %User{uuid: user_uuid} = user = get_auth(socket)

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "notifications:users:#{user_uuid}")
    :timer.send_interval(:timer.seconds(10), :tick)

    {:ok,
     assign(socket,
       notifications: NotificationContext.list_notifications(user),
       now: DateTime.utc_now()
     )}
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info({:deleted, %Notification{uuid: uuid}, _version}, socket),
    do:
      {:noreply,
       assign(socket,
         notifications:
           Enum.reject(socket.assigns.notifications, &match?(%Notification{uuid: ^uuid}, &1))
       )}

  def handle_info({:updated, %Notification{uuid: uuid} = notification, _version}, socket),
    do:
      {:noreply,
       assign(socket,
         notifications:
           Enum.map(
             socket.assigns.notifications,
             &if(match?(%Notification{uuid: ^uuid}, &1), do: notification, else: &1)
           )
       )}

  def handle_info({:created, %Notification{} = notification, _version}, socket),
    do:
      {:noreply,
       assign(socket,
         notifications: [notification | socket.assigns.notifications]
       )}

  def handle_info(:read_all, socket),
    do:
      {:noreply,
       assign(socket, notifications: NotificationContext.list_notifications(get_auth(socket)))}

  def handle_info(:deleted_all, socket),
    do:
      {:noreply,
       assign(socket, notifications: NotificationContext.list_notifications(get_auth(socket)))}

  @impl Phoenix.LiveView
  def handle_event("read", %{"uuid" => uuid} = _params, socket) do
    socket.assigns.notifications
    |> Enum.filter(&match?(%Notification{uuid: ^uuid}, &1))
    |> Enum.each(
      &({:ok, _notification} = NotificationContext.update_notification(&1, %{read: true}))
    )

    send_update(HygeiaWeb.Dropdown, id: "notifications-try-dropdown", dropdown_open: false)

    {:noreply, socket}
  end

  def handle_event("delete", %{"uuid" => uuid} = _params, socket) do
    socket.assigns.notifications
    |> Enum.filter(&match?(%Notification{uuid: ^uuid}, &1))
    |> Enum.each(&({:ok, _notification} = NotificationContext.delete_notification(&1)))

    {:noreply, socket}
  end

  def handle_event("delete_all", _params, socket) do
    :ok = NotificationContext.delete_all_notifications(get_auth(socket))

    {:noreply, socket}
  end

  def handle_event("read_all", _params, socket) do
    :ok = NotificationContext.mark_all_as_read(get_auth(socket))

    {:noreply, socket}
  end

  defp render_body(assigns, notification)

  defp render_body(assigns, %Notification{uuid: uuid, body: %Notification.CaseAssignee{} = body}) do
    ~H"""
    <HygeiaWeb.Notification.CaseAssignee
      id={{ "notifications_tray_notification_body_#{uuid}" }}
      body={{ body }}
    />
    """
  end

  defp render_body(assigns, %Notification{
         uuid: uuid,
         body: %Notification.PossibleIndexSubmitted{} = body
       }) do
    ~H"""
    <HygeiaWeb.Notification.PossibleIndexSubmitted
      id={{ "notifications_tray_notification_body_#{uuid}" }}
      body={{ body }}
    />
    """
  end

  defp render_body(assigns, %Notification{
         uuid: uuid,
         body: %Notification.EmailSendFailed{} = body
       }) do
    ~H"""
    <HygeiaWeb.Notification.EmailSendFailed
      id={{ "notifications_tray_notification_body_#{uuid}" }}
      body={{ body }}
    />
    """
  end
end
