defmodule HygeiaWeb.MutationLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{name: "some name", ism_code: 42}
  @update_attrs %{name: "some updated name", ism_code: 143}
  @invalid_attrs %{name: nil, ism_code: nil}

  defp create_mutation(_tags) do
    %{mutation: mutation_fixture()}
  end

  describe "Index" do
    setup [:create_mutation]

    test "lists all mutations", %{conn: conn, mutation: mutation} do
      {:ok, _index_live, html} = live(conn, Routes.mutation_index_path(conn, :index))

      assert html =~ "Listing Mutations"
      assert html =~ mutation.name
    end

    test "deletes mutation in listing", %{conn: conn, mutation: mutation} do
      {:ok, index_live, _html} = live(conn, Routes.mutation_index_path(conn, :index))

      assert index_live
             |> element("#mutation-#{mutation.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#mutation-#{mutation.uuid}")
    end
  end

  describe "Create" do
    test "saves new mutation", %{conn: conn} do
      {:ok, create_live, _html} = live(conn, Routes.mutation_create_path(conn, :create))

      assert create_live
             |> form("#mutation-form", mutation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#mutation-form", mutation: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Mutation created successfully"
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_mutation]

    test "displays mutation", %{conn: conn, mutation: mutation} do
      {:ok, _show_live, html} = live(conn, Routes.mutation_show_path(conn, :show, mutation))

      assert html =~ mutation.name
    end

    test "updates mutation within modal", %{conn: conn, mutation: mutation} do
      {:ok, show_live, _html} = live(conn, Routes.mutation_show_path(conn, :show, mutation))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.mutation_show_path(conn, :edit, mutation))

      assert show_live
             |> form("#mutation-form", mutation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      html =
        show_live
        |> form("#mutation-form", mutation: @update_attrs)
        |> render_submit()

      assert_patch(show_live, Routes.mutation_show_path(conn, :show, mutation))

      assert html =~ "Mutation updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes mutation", %{conn: conn, mutation: mutation} do
      {:ok, show_live, _html} = live(conn, Routes.mutation_show_path(conn, :show, mutation))

      assert show_live |> element("a", "Delete") |> render_click()

      {:ok, index_live, _html} = live(conn, Routes.mutation_index_path(conn, :index))

      refute has_element?(index_live, "#mutation-#{mutation.uuid}")
    end
  end
end
