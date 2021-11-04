defmodule HygeiaWeb.RowLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.Repo
  alias Hygeia.UserContext.Grant
  alias Hygeia.UserContext.User

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp load_user_tenant(%{user: %User{grants: [%Grant{tenant: tenant}]}} = _tags),
    do: %{tenant: tenant}

  valid_import_file_path =
    Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")

  defp create_import(%{tenant: tenant}) do
    {:ok, import} =
      ImportContext.create_import(
        tenant,
        MIME.type("xlsx"),
        unquote(valid_import_file_path),
        %{type: :ism_2021_06_11_test}
      )

    %{import: Repo.preload(import, :rows)}
  end

  describe "Index" do
    setup [:load_user_tenant, :create_import]

    test "lists all rows", %{conn: conn, import: %Import{rows: [row | _]} = import} do
      {:ok, _index_live, html} = live(conn, Routes.row_index_path(conn, :index, import, :pending))

      assert html =~ row.uuid
    end
  end

  describe "Apply" do
    setup [:load_user_tenant, :create_import]

    test "displays row and redirects to next", %{
      conn: conn,
      import: %Import{rows: [row, row2 | _]}
    } do
      {:ok, apply_live, html} = live(conn, Routes.row_apply_path(conn, :apply, row))

      assert html =~ row.uuid

      assert {:ok, _apply_view, html} =
               apply_live
               |> element(".execute-next")
               |> render_click()
               # Redirect to next helper
               |> follow_redirect(conn)
               # Redirect to next row apply
               |> follow_redirect(conn)

      assert html =~ row2.uuid
    end

    test "displays row and redirects to show", %{conn: conn, import: %Import{rows: [row | _]}} do
      {:ok, apply_live, html} = live(conn, Routes.row_apply_path(conn, :apply, row))

      assert html =~ row.uuid

      assert {:ok, _show_view, html} =
               apply_live
               |> element(".execute-show")
               |> render_click()
               |> follow_redirect(conn, Routes.row_show_path(conn, :show, row))

      assert html =~ row.uuid
    end
  end
end
