defmodule HygeiaWeb.PositionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.Repo

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  @create_attrs %{position: "some position"}
  @update_attrs %{position: "some updated position"}
  @invalid_attrs %{position: nil}

  defp create_position(_tags) do
    %{organisation: organisation, person: person} =
      position = Repo.preload(position_fixture(), organisation: [], person: [])

    %{position: position, organisation: organisation, person: person}
  end

  describe "Index" do
    setup [:create_position]

    test "lists all positions", %{conn: conn, position: position, organisation: organisation} do
      {:ok, _index_live, html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Show Organisation"
      assert html =~ position.position
    end

    test "saves new position", %{conn: conn, organisation: organisation, person: person} do
      {:ok, index_live, _html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert index_live |> element("a", "New Position") |> render_click() =~
               "New Position"

      assert_patch(
        index_live,
        Routes.organisation_show_path(conn, :position_new, organisation.uuid)
      )

      assert index_live
             |> form("#position-form", position: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#position-form", position: Map.put(@create_attrs, :person_uuid, person.uuid))
        |> render_submit()
        |> follow_redirect(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Position created successfully"
      assert html =~ "some position"
    end

    test "updates position in listing", %{
      conn: conn,
      position: position,
      organisation: organisation
    } do
      {:ok, index_live, _html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert index_live |> element("#position-#{position.uuid} a", "Edit") |> render_click() =~
               "Edit Position"

      assert_patch(
        index_live,
        Routes.organisation_show_path(conn, :position_edit, organisation.uuid, position.uuid)
      )

      assert index_live
             |> form("#position-form", position: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#position-form", position: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Position updated successfully"
      assert html =~ "some updated position"
    end

    test "deletes position in listing", %{
      conn: conn,
      position: position,
      organisation: organisation
    } do
      {:ok, index_live, _html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert index_live |> element("#position-#{position.uuid} a", "Delete") |> render_click()
      refute has_element?(index_live, "#position-#{position.uuid}")
    end
  end
end
