defmodule HygeiaWeb.DivisionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{
    shares_address: true,
    title: "some title",
    description: "some description"
  }
  @update_attrs %{
    address: %{
      address: "some updated address",
      zip: "some updated zip",
      place: "some updated city",
      subdivision: "SG",
      country: "CH"
    },
    shares_address: false,
    title: "some updated title",
    description: "some updated description"
  }
  @invalid_attrs %{
    title: nil,
    description: nil
  }

  defp create_organisation(_tags) do
    %{organisation: organisation_fixture()}
  end

  defp create_division(%{organisation: organisation}) do
    %{division: division_fixture(organisation)}
  end

  describe "Index" do
    setup [:create_organisation, :create_division]

    test "lists all divisions", %{conn: conn, organisation: organisation, division: division} do
      {:ok, _index_live, html} =
        live(conn, Routes.division_index_path(conn, :index, organisation))

      assert html =~ organisation.name
      assert html =~ division.title
    end

    test "deletes division in listing", %{
      conn: conn,
      organisation: organisation,
      division: division
    } do
      {:ok, index_live, _html} =
        live(conn, Routes.division_index_path(conn, :index, organisation))

      assert index_live
             |> element("#division-#{division.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#division-#{division.uuid}")
    end
  end

  describe "Create" do
    setup [:create_organisation]

    test "saves new division", %{conn: conn, organisation: organisation} do
      {:ok, create_live, _html} =
        live(conn, Routes.division_create_path(conn, :create, organisation))

      assert create_live
             |> form("#division-form", division: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#division-form", division: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Division created successfully"
      assert html =~ "some title"
    end
  end

  describe "Show" do
    setup [:create_organisation, :create_division]

    test "displays division", %{conn: conn, division: division} do
      {:ok, _show_live, html} = live(conn, Routes.division_show_path(conn, :show, division))

      assert html =~ division.title
    end

    test "updates division", %{conn: conn, division: division} do
      {:ok, show_live, _html} = live(conn, Routes.division_show_path(conn, :show, division))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.division_show_path(conn, :edit, division))

      assert show_live
             |> form("#division-form", division: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      assert show_live
             |> form("#division-form", division: Map.drop(@update_attrs, [:address]))
             |> render_change() =~ "can&apos;t be blank"

      html =
        show_live
        |> form("#division-form", division: @update_attrs)
        |> render_submit()

      assert_patch(show_live, Routes.division_show_path(conn, :show, division))

      assert html =~ "Division updated successfully"
      assert html =~ "some updated title"
    end
  end

  describe "Merge" do
    setup [:create_organisation]

    test "merges divisions", %{conn: conn, organisation: organisation} do
      {:ok, merge_live, _html} =
        live(conn, Routes.division_merge_path(conn, :merge, organisation))

      delete = division_fixture(organisation)
      into = division_fixture(organisation)

      render_hook(merge_live, :change_delete, %{uuid: delete.uuid})
      assert render_hook(merge_live, :change_into, %{uuid: delete.uuid}) =~ "must not be the same"

      render_hook(merge_live, :change_into, %{uuid: into.uuid})

      {:ok, _view, html} =
        merge_live
        |> form("#division-merge-form")
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Divisions merged successfully"
      assert html =~ into.title
    end
  end
end
