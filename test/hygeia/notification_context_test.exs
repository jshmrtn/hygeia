defmodule Hygeia.NotificationContextTest do
  use Hygeia.DataCase

  alias Hygeia.NotificationContext
  alias Hygeia.NotificationContext.Notification

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "notifications" do
    @valid_attrs %{
      body: %{__type__: :case_assignee, case_uuid: "a4f86204-9510-4b69-aef2-f8e78bab5760"},
      notified: true,
      read: true
    }
    @update_attrs %{body: %{}, notified: false, read: false}
    @invalid_attrs %{body: nil, notified: nil, read: nil}

    test "list_notifications/0 returns all notifications" do
      notification = notification_fixture()
      assert NotificationContext.list_notifications() == [notification]
    end

    test "get_notification!/1 returns the notification with given id" do
      notification = notification_fixture()
      assert NotificationContext.get_notification!(notification.uuid) == notification
    end

    test "create_notification/1 with valid data creates a notification" do
      assert {:ok, %Notification{} = notification} =
               NotificationContext.create_notification(user_fixture(), @valid_attrs)

      assert notification.notified == true
      assert notification.read == true
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               NotificationContext.create_notification(user_fixture(), @invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()

      assert {:ok, %Notification{} = notification} =
               NotificationContext.update_notification(notification, @update_attrs)

      assert notification.notified == false
      assert notification.read == false
    end

    test "update_notification/2 with invalid data returns error changeset" do
      notification = notification_fixture()

      assert {:error, %Ecto.Changeset{}} =
               NotificationContext.update_notification(notification, @invalid_attrs)

      assert notification == NotificationContext.get_notification!(notification.uuid)
    end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = NotificationContext.delete_notification(notification)

      assert_raise Ecto.NoResultsError, fn ->
        NotificationContext.get_notification!(notification.uuid)
      end
    end

    test "change_notification/1 returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = NotificationContext.change_notification(notification)
    end
  end
end
