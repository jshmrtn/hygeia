defmodule Hygeia.SystemMessageContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.SystemMessageContext
  alias Hygeia.SystemMessageContext.SystemMessage

  @moduletag origin: :test
  @moduletag originator: :noone

  setup do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "system_message_cache")

    :ok
  end

  describe "system_messages" do
    @valid_attrs %{
      end_date: ~N[2010-04-17 14:00:00],
      text: "some message",
      start_date: ~N[2010-04-17 10:00:00],
      roles: ["admin"]
    }
    @update_attrs %{
      end_date: ~N[2011-05-18 14:00:00],
      text: "some updated message",
      start_date: ~N[2011-05-18 10:00:00],
      roles: ["tracer"]
    }
    @invalid_attrs %{end_date: nil, text: nil, start_date: nil, roles: nil}

    test "list_system_messages/0 returns all system_messages" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert SystemMessageContext.list_system_messages() == [system_message]
    end

    test "get_system_message!/1 returns the system_message with given id" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert SystemMessageContext.get_system_message!(system_message.uuid) == system_message
    end

    test "create_system_message/1 with valid data creates a system_message" do
      assert {:ok, %SystemMessage{} = system_message} =
               SystemMessageContext.create_system_message(@valid_attrs)

      assert_receive :refresh

      assert system_message.end_date == ~N[2010-04-17 14:00:00.000000]
      assert system_message.text == "some message"
      assert system_message.start_date == ~N[2010-04-17 10:00:00.000000]
    end

    test "create_system_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SystemMessageContext.create_system_message(@invalid_attrs)
    end

    test "update_system_message/2 with valid data updates the system_message" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert {:ok, %SystemMessage{} = system_message} =
               SystemMessageContext.update_system_message(system_message, @update_attrs)

      assert_receive :refresh

      assert system_message.end_date == ~N[2011-05-18 14:00:00.000000]
      assert system_message.text == "some updated message"
      assert system_message.start_date == ~N[2011-05-18 10:00:00.000000]
    end

    test "update_system_message/2 with invalid data returns error changeset" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert {:error, %Ecto.Changeset{}} =
               SystemMessageContext.update_system_message(system_message, @invalid_attrs)

      assert system_message == SystemMessageContext.get_system_message!(system_message.uuid)
    end

    test "delete_system_message/1 deletes the system_message" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert {:ok, %SystemMessage{}} = SystemMessageContext.delete_system_message(system_message)

      assert_receive :refresh

      assert_raise Ecto.NoResultsError, fn ->
        SystemMessageContext.get_system_message!(system_message.uuid)
      end
    end

    test "change_system_message/1 returns a system_message changeset" do
      system_message = system_message_fixture()

      assert_receive :refresh

      assert %Ecto.Changeset{} = SystemMessageContext.change_system_message(system_message)
    end
  end
end
