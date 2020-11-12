defmodule HygeiaWeb.ProfessionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_profession(_tags) do
    %{profession: profession_fixture()}
  end

  describe "Index" do
    setup [:create_profession]

    test "lists all professions", %{conn: conn, profession: profession} do
      {:ok, _index_live, html} = live(conn, Routes.profession_index_path(conn, :index))

      assert html =~ "Listing Professions"
      assert html =~ profession.name
    end

    test "deletes profession in listing", %{conn: conn, profession: profession} do
      {:ok, index_live, _html} = live(conn, Routes.profession_index_path(conn, :index))

      assert index_live |> element("#profession-#{profession.uuid} a.delete") |> render_click()
      refute has_element?(index_live, "#profession-#{profession.uuid}")
    end
  end

  describe "Create" do
    test "saves new profession", %{conn: conn} do
      {:ok, create_live, _html} = live(conn, Routes.profession_create_path(conn, :create))

      assert create_live
             |> form("#profession-form", profession: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#profession-form", profession: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Profession created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_profession]

    test "displays profession", %{conn: conn, profession: profession} do
      {:ok, _show_live, html} = live(conn, Routes.profession_show_path(conn, :show, profession))

      assert html =~ profession.name
    end

    test "updates profession within modal", %{conn: conn, profession: profession} do
      {:ok, show_live, _html} = live(conn, Routes.profession_show_path(conn, :show, profession))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.profession_show_path(conn, :edit, profession))

      assert show_live
             |> form("#profession-form", profession: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      html =
        show_live
        |> form("#profession-form", profession: @update_attrs)
        |> render_submit()

      assert_patch(show_live, Routes.profession_show_path(conn, :show, profession))

      assert html =~ "Profession updated successfully"
      assert html =~ "some updated name"
    end
  end
end
