defmodule HygeiaWeb.OrganisationLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{
    address: %{
      address: "some address",
      zip: "some zip",
      place: "some city",
      subdivision: "SG",
      country: "CH"
    },
    name: "some name",
    notes: "some notes"
  }
  @update_attrs %{
    address: %{
      address: "some updated address",
      zip: "some updated zip",
      place: "some updated city",
      subdivision: "SG",
      country: "CH"
    },
    name: "some updated name",
    notes: "some updated notes"
  }
  @invalid_attrs %{
    address: %{},
    name: nil,
    notes: nil
  }

  defp create_organisation(_tags) do
    %{organisation: organisation_fixture()}
  end

  describe "Index" do
    setup [:create_organisation]

    test "lists all organisations", %{conn: conn, organisation: organisation} do
      {:ok, _index_live, html} = live(conn, Routes.organisation_index_path(conn, :index))

      assert html =~ "Listing Organisations"
      assert html =~ organisation.name
    end

    test "deletes organisation in listing", %{conn: conn, organisation: organisation} do
      {:ok, index_live, _html} = live(conn, Routes.organisation_index_path(conn, :index))

      assert index_live
             |> element("#organisation-#{organisation.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#organisation-#{organisation.uuid}")
    end
  end

  describe "Create" do
    test "saves new organisation", %{conn: conn} do
      {:ok, create_live, _html} = live(conn, Routes.organisation_create_path(conn, :create))

      assert create_live
             |> form("#organisation-form", organisation: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#organisation-form", organisation: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Organisation created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_organisation]

    test "displays organisation", %{conn: conn, organisation: organisation} do
      {:ok, _show_live, html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ organisation.name
    end

    test "updates organisation within modal", %{conn: conn, organisation: organisation} do
      {:ok, show_live, _html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.organisation_show_path(conn, :edit, organisation))

      assert show_live
             |> form("#organisation-form", organisation: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      html =
        show_live
        |> form("#organisation-form", organisation: @update_attrs)
        |> render_submit()

      assert_patch(show_live, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Organisation updated successfully"
      assert html =~ "some updated name"
    end

    test "show suspected duplicate", %{conn: conn, organisation: orga_show} do
      orga_duplicate_name =
        organisation_fixture(%{
          name: "JOHSMARTIN GmbH",
          address: nil
        })

      orga_duplicate_address =
        organisation_fixture(%{
          name: "Other Company",
          address: %{
            address: "Neugasse 51",
            zip: "9000",
            place: "St. Gallen",
            country: "CH"
          }
        })

      {:ok, _show_live, html} = live(conn, Routes.organisation_show_path(conn, :show, orga_show))

      assert html =~ orga_duplicate_name.uuid
      assert html =~ orga_duplicate_address.uuid
    end
  end

  describe "Merge" do
    test "merges organisations", %{conn: conn} do
      {:ok, merge_live, _html} = live(conn, Routes.organisation_merge_path(conn, :merge))

      delete = organisation_fixture()
      into = organisation_fixture()

      render_hook(merge_live, :change_delete, %{uuid: delete.uuid})
      assert render_hook(merge_live, :change_into, %{uuid: delete.uuid}) =~ "must not be the same"

      render_hook(merge_live, :change_into, %{uuid: into.uuid})

      {:ok, _view, html} =
        merge_live
        |> form("#organisation-merge-form")
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Organisations merged successfully"
      assert html =~ into.name
    end
  end
end
