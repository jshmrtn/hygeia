defmodule HygeiaWeb.OrganisationLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone

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

    test "saves new organisation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.organisation_index_path(conn, :index))

      assert index_live |> element("a", "New Organisation") |> render_click() =~
               "New Organisation"

      assert_patch(index_live, Routes.organisation_index_path(conn, :new))

      assert index_live
             |> form("#organisation-form", organisation: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#organisation-form", organisation: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.organisation_index_path(conn, :index))

      assert html =~ "Organisation created successfully"
      assert html =~ "some name"
    end

    test "updates organisation in listing", %{conn: conn, organisation: organisation} do
      {:ok, index_live, _html} = live(conn, Routes.organisation_index_path(conn, :index))

      assert index_live
             |> element("#organisation-#{organisation.uuid} a", "Edit")
             |> render_click() =~
               "Edit Organisation"

      assert_patch(index_live, Routes.organisation_index_path(conn, :edit, organisation))

      assert index_live
             |> form("#organisation-form", organisation: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#organisation-form", organisation: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.organisation_index_path(conn, :index))

      assert html =~ "Organisation updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes organisation in listing", %{conn: conn, organisation: organisation} do
      {:ok, index_live, _html} = live(conn, Routes.organisation_index_path(conn, :index))

      assert index_live
             |> element("#organisation-#{organisation.uuid} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#organisation-#{organisation.uuid}")
    end
  end

  describe "Show" do
    setup [:create_organisation]

    test "displays organisation", %{conn: conn, organisation: organisation} do
      {:ok, _show_live, html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Show Organisation"
      assert html =~ organisation.name
    end

    test "updates organisation within modal", %{conn: conn, organisation: organisation} do
      {:ok, show_live, _html} =
        live(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Organisation"

      assert_patch(show_live, Routes.organisation_show_path(conn, :edit, organisation))

      assert show_live
             |> form("#organisation-form", organisation: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#organisation-form", organisation: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.organisation_show_path(conn, :show, organisation))

      assert html =~ "Organisation updated successfully"
      assert html =~ "some updated name"
    end
  end
end
