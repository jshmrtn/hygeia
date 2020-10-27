defmodule HygeiaWeb.PersonLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  @create_attrs %{
    first_name: "some first_name",
    last_name: "some last_name"
  }
  @update_attrs %{
    first_name: "some updated first_name",
    last_name: "some updated last_name"
  }
  @invalid_attrs %{
    first_name: nil,
    last_name: nil
  }

  defp create_person(_tags) do
    %{person: person_fixture()}
  end

  describe "Index" do
    setup [:create_person]

    test "lists all people", %{conn: conn, person: person} do
      {:ok, _index_live, html} = live(conn, Routes.person_index_path(conn, :index))

      assert html =~ "Listing People"
      assert html =~ person.first_name
    end

    test "deletes person in listing", %{conn: conn, person: person} do
      {:ok, index_live, _html} = live(conn, Routes.person_index_path(conn, :index))

      assert index_live |> element("#person-#{person.uuid} a[title=Delete]") |> render_click()
      refute has_element?(index_live, "#person-#{person.uuid}")
    end
  end

  describe "Create" do
    test "saves new person", %{conn: conn} do
      tenant = tenant_fixture()
      {:ok, create_live, _html} = live(conn, Routes.person_create_path(conn, :create))

      assert create_live
             |> form("#person-form", person: Map.put(@invalid_attrs, :tenant_uuid, tenant.uuid))
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#person-form", person: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Person created successfully"
      assert html =~ "some first_name"
    end
  end

  describe "Show" do
    setup [:create_person]

    test "displays person", %{conn: conn, person: person} do
      {:ok, _show_live, html} = live(conn, Routes.person_show_path(conn, :show, person))

      assert html =~ "Show Person"
      assert html =~ person.first_name
    end

    test "updates person within modal", %{conn: conn, person: person} do
      {:ok, edit_live, _html} = live(conn, Routes.person_show_path(conn, :edit, person))

      assert edit_live
             |> form("#person-form", person: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      html =
        edit_live
        |> form("#person-form", person: @update_attrs)
        |> render_submit()

      assert_patch(edit_live, Routes.person_show_path(conn, :show, person))

      assert html =~ "Person updated successfully"
      assert html =~ "some updated first_name"
    end
  end
end
