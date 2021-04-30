defmodule HygeiaWeb.ImportLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.UserContext.Grant
  alias Hygeia.UserContext.User

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp load_user_tenant(%{user: %User{grants: [%Grant{tenant: tenant}]}} = _tags),
    do: %{tenant: tenant}

  @create_attrs %{
    type: :ism_2021_06_11_test
  }
  @invalid_attrs %{
    type: nil
  }

  valid_import_file_path =
    Application.app_dir(:hygeia, "priv/test/import/example_ism_2021_06_11_test.xlsx")

  @valid_import_file %{
    last_modified: 1_594_171_879_000,
    name: "example_ism_2021_06_11_test.xlsx",
    content: File.read!(valid_import_file_path),
    type: MIME.type("xlsx")
  }

  defp create_import(%{tenant: tenant}) do
    {:ok, import} =
      ImportContext.create_import(
        tenant,
        MIME.type("xlsx"),
        unquote(valid_import_file_path),
        @create_attrs
      )

    %{import: import}
  end

  describe "Index" do
    setup [:load_user_tenant, :create_import]

    test "lists all imports", %{conn: conn, import: import} do
      {:ok, _index_live, html} = live(conn, Routes.import_index_path(conn, :index))

      assert html =~ Type.translate(import.type)
    end

    test "deletes import in listing", %{conn: conn, import: import} do
      {:ok, index_live, _html} = live(conn, Routes.import_index_path(conn, :index))

      assert index_live
             |> element("#import-#{import.uuid} a.delete")
             |> render_click()

      refute has_element?(index_live, "#import-#{import.uuid}")
    end
  end

  describe "Create" do
    setup [:load_user_tenant]

    test "saves new import", %{conn: conn, tenant: tenant} do
      {:ok, create_live, _html} = live(conn, Routes.import_create_path(conn, :create))

      assert create_live
             |> form("#import-form",
               import: Map.merge(@invalid_attrs, %{tenant_uuid: tenant.uuid})
             )
             |> render_change() =~ "can&#39;t be blank"

      assert create_live
             |> file_input("#import-form", :file, [@valid_import_file])
             |> render_upload("example_ism_2021_06_11_test.xlsx") =~ "100%"

      {:ok, _, html} =
        create_live
        |> form("#import-form", import: Map.merge(@create_attrs, %{tenant_uuid: tenant.uuid}))
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Import created successfully"
      assert html =~ Type.translate(@create_attrs.type)
    end
  end

  describe "Show" do
    setup [:load_user_tenant, :create_import]

    test "displays division", %{conn: conn, import: import} do
      {:ok, _show_live, html} = live(conn, Routes.import_show_path(conn, :show, import))

      assert html =~ Type.translate(import.type)
    end
  end
end
