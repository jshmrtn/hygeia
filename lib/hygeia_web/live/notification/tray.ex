defmodule HygeiaWeb.Notification.Tray do
  @moduledoc false

  use HygeiaWeb, :surface_view_bare

  import Ecto.Query

  alias Hygeia.NotificationContext
  alias Hygeia.NotificationContext.Notification
  alias Hygeia.Repo
  alias Hygeia.UserContext.User

  data notifications, :list, default: []
  data notification_show_limit, :integer, default: 50
  data unread_notification_count, :integer, default: 0
  data total_count, :integer, default: 0
  data now, :map, default: nil

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %User{uuid: user_uuid} = get_auth(socket)

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "notifications:users:#{user_uuid}")
    :timer.send_interval(:timer.seconds(10), :tick)

    {:ok, socket |> assign(now: DateTime.utc_now()) |> reload_notifications()}
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info({:deleted, _notification, _version}, socket),
    do: {:noreply, reload_notifications(socket)}

  def handle_info({:updated, _notification, _version}, socket),
    do: {:noreply, reload_notifications(socket)}

  def handle_info({:created, %Notification{} = notification, _version}, socket),
    do:
      {:noreply,
       assign(socket,
         notifications: [notification | socket.assigns.notifications]
       )}

  def handle_info(:read_all, socket),
    do: {:noreply, reload_notifications(socket)}

  def handle_info(:deleted_all, socket),
    do: {:noreply, reload_notifications(socket)}

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

  defp reload_notifications(socket) do
    user = get_auth(socket)

    base_query = NotificationContext.list_notifications_query(user)

    unread_query = from(notification in base_query, where: not notification.read)

    limit_notifications_query =
      from(notification in base_query, limit: ^socket.assigns.notification_show_limit)

    assign(socket,
      notifications: Repo.all(limit_notifications_query),
      unread_notification_count: Repo.aggregate(unread_query, :count),
      total_count: Repo.aggregate(base_query, :count)
    )
  end
end
