defmodule HygeiaWeb.TenantLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_tenant(_tags) do
    %{tenant: tenant_fixture()}
  end

  describe "Index" do
    setup [:create_tenant]

    test "lists all tenants", %{conn: conn, tenant: tenant} do
      {:ok, _index_live, html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert html =~ "Listing Tenants"
      assert html =~ tenant.name
    end

    test "saves new tenant", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert index_live |> element("a", "New Tenant") |> render_click() =~
               "New Tenant"

      assert_patch(index_live, Routes.tenant_index_path(conn, :new))

      assert index_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#tenant-form", tenant: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tenant_index_path(conn, :index))

      assert html =~ "Tenant created successfully"
      assert html =~ "some name"
    end

    test "updates tenant in listing", %{conn: conn, tenant: tenant} do
      {:ok, index_live, _html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert index_live |> element("#tenant-#{tenant.uuid} a", "Edit") |> render_click() =~
               "Edit Tenant"

      assert_patch(index_live, Routes.tenant_index_path(conn, :edit, tenant))

      assert index_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#tenant-form", tenant: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tenant_index_path(conn, :index))

      assert html =~ "Tenant updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes tenant in listing", %{conn: conn, tenant: tenant} do
      {:ok, index_live, _html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert index_live |> element("#tenant-#{tenant.uuid} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tenant-#{tenant.uuid}")
    end
  end

  describe "Show" do
    setup [:create_tenant]

    test "displays tenant", %{conn: conn, tenant: tenant} do
      {:ok, _show_live, html} = live(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ "Show Tenant"
      assert html =~ tenant.name
    end

    test "updates tenant within modal", %{conn: conn, tenant: tenant} do
      {:ok, show_live, _html} = live(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tenant"

      assert_patch(show_live, Routes.tenant_show_path(conn, :edit, tenant))

      assert show_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#tenant-form", tenant: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ "Tenant updated successfully"
      assert html =~ "some updated name"
    end
  end
end
