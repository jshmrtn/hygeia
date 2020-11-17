defmodule HygeiaWeb.InfectionPlaceTypeLiveTest do
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

  defp create_infection_place_type(_tags) do
    %{infection_place_type: infection_place_type_fixture()}
  end

  describe "Index" do
    setup [:create_infection_place_type]

    test "lists all infection_place_types", %{
      conn: conn,
      infection_place_type: infection_place_type
    } do
      {:ok, _index_live, html} = live(conn, Routes.infection_place_type_index_path(conn, :index))

      assert html =~ "Infection place types"
      assert html =~ infection_place_type.name
    end

    test "deletes infection_place_type in listing", %{
      conn: conn,
      infection_place_type: infection_place_type
    } do
      {:ok, index_live, _html} = live(conn, Routes.infection_place_type_index_path(conn, :index))

      assert index_live
             |> element("#infection_place_type-#{infection_place_type.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#infection_place_type-#{infection_place_type.uuid}")
    end
  end

  describe "Create" do
    test "saves new infection_place_type", %{conn: conn} do
      {:ok, create_live, _html} =
        live(conn, Routes.infection_place_type_create_path(conn, :create))

      assert create_live
             |> form("#infection_place_type-form", infection_place_type: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#infection_place_type-form", infection_place_type: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Infection place type created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_infection_place_type]

    test "displays infection_place_type", %{
      conn: conn,
      infection_place_type: infection_place_type
    } do
      {:ok, _show_live, html} =
        live(conn, Routes.infection_place_type_show_path(conn, :show, infection_place_type))

      assert html =~ infection_place_type.name
    end

    test "updates infection_place_type within modal", %{
      conn: conn,
      infection_place_type: infection_place_type
    } do
      {:ok, show_live, _html} =
        live(conn, Routes.infection_place_type_show_path(conn, :show, infection_place_type))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(
        show_live,
        Routes.infection_place_type_show_path(conn, :edit, infection_place_type)
      )

      assert show_live
             |> form("#infection_place_type-form", infection_place_type: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      html =
        show_live
        |> form("#infection_place_type-form", infection_place_type: @update_attrs)
        |> render_submit()

      assert_patch(
        show_live,
        Routes.infection_place_type_show_path(conn, :show, infection_place_type)
      )

      assert html =~ "Infection place type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
