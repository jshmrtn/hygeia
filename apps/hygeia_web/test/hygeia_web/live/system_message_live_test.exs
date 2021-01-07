defmodule HygeiaWeb.SystemMessageLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{
    end_date: ~D[2010-04-17],
    text: "some message",
    start_date: ~D[2010-04-17],
    roles: ["admin"]
  }
  @update_attrs %{
    end_date: ~D[2011-05-18],
    text: "some updated message",
    start_date: ~D[2011-05-18],
    roles: ["tracer"]
  }
  @invalid_attrs %{end_date: nil, text: nil, start_date: nil}

  defp create_system_message(_attrs) do
    %{system_message: system_message_fixture()}
  end

  describe "Index" do
    setup [:create_system_message]

    test "lists all system_messages", %{conn: conn, system_message: system_message} do
      {:ok, _index_live, html} = live(conn, Routes.system_message_index_path(conn, :index))

      assert html =~ "Listing System Messages"
      assert html =~ system_message.text
    end

    test "deletes system_message in listing", %{conn: conn, system_message: system_message} do
      {:ok, index_live, _html} = live(conn, Routes.system_message_index_path(conn, :index))

      assert index_live
             |> element("#system_message-#{system_message.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#system_message-#{system_message.uuid}")
    end
  end

  describe "Create" do
    test "saves new system_message", %{conn: conn} do
      {:ok, create_live, _html} = live(conn, Routes.system_message_create_path(conn, :create))

      assert create_live
             |> form("#system_message-form", system_message: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#system_message-form", system_message: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "some message"
    end
  end

  describe "Show" do
    setup [:create_system_message]

    test "displays system_message", %{conn: conn, system_message: system_message} do
      {:ok, _show_live, html} =
        live(conn, Routes.system_message_show_path(conn, :show, system_message.uuid))

      assert html =~ ""
      assert html =~ system_message.text
    end

    test "updates system_message within modal", %{conn: conn, system_message: system_message} do
      {:ok, show_live, _html} =
        live(conn, Routes.system_message_show_path(conn, :show, system_message.uuid))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.system_message_show_path(conn, :edit, system_message.uuid))

      assert show_live
             |> form("#system_message-form", system_message: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      assert html =
               show_live
               |> form("#system_message-form", system_message: @update_attrs)
               |> render_submit()

      assert_patch(show_live, Routes.system_message_show_path(conn, :show, system_message.uuid))

      assert html =~ "System Message updated successfully"
      assert html =~ "some updated message"
    end
  end
end
