defmodule HygeiaWeb.TenantLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:webmaster]]

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name",
    outgoing_mail_configuration_type: "smtp",
    from_email: "info@kanton.com",
    case_management_enabled: true,
    iam_domain: "test",
    outgoing_mail_configuration: %{
      __type__: "smtp",
      enable_relay: true,
      relay: %{
        server: "kanton.com",
        port: 2525,
        username: "test1",
        change_password: true,
        password: "test1"
      }
    },
    outgoing_sms_configuration_type: "websms",
    outgoing_sms_configuration: %{
      __type__: "websms",
      access_token: "test1111"
    }
  }
  @invalid_attrs %{name: nil}

  defp create_tenant(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{tenant: tenant}
  end

  describe "Index" do
    setup [:create_tenant]

    test "lists all tenants", %{conn: conn, tenant: tenant} do
      {:ok, _index_live, html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert html =~ "Listing Tenants"
      assert html =~ tenant.name
    end

    test "deletes tenant in listing", %{conn: conn, tenant: tenant} do
      {:ok, index_live, _html} = live(conn, Routes.tenant_index_path(conn, :index))

      assert index_live |> element("#tenant-#{tenant.uuid} a.delete") |> render_click()
      refute has_element?(index_live, "#tenant-#{tenant.uuid}")
    end
  end

  describe "Create" do
    test "saves new tenant", %{conn: conn} do
      {:ok, create_live, _html} = live(conn, Routes.tenant_create_path(conn, :create))

      assert create_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#tenant-form", tenant: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_tenant]

    test "displays tenant", %{conn: conn, tenant: tenant} do
      {:ok, _show_live, html} = live(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ tenant.name
    end

    test "updates tenant within modal", %{conn: conn, tenant: tenant} do
      {:ok, show_live, _html} = live(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.tenant_show_path(conn, :edit, tenant))

      assert show_live
             |> form("#tenant-form", tenant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tenant-form",
               tenant:
                 Map.drop(@update_attrs, [
                   :outgoing_sms_configuration,
                   :outgoing_sms_configuration_type,
                   :outgoing_mail_configuration,
                   :outgoing_mail_configuration_type,
                   :from_email
                 ])
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 Map.drop(@update_attrs, [
                   :outgoing_sms_configuration,
                   :outgoing_mail_configuration
                 ])
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 update_in(@update_attrs, [:outgoing_mail_configuration], &Map.drop(&1, [:relay]))
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 update_in(
                   @update_attrs,
                   [:outgoing_mail_configuration, :relay],
                   &Map.drop(&1, [:password])
                 )
             )
             |> render_change()

      assert html =
               show_live
               |> form("#tenant-form", tenant: @update_attrs)
               |> render_submit()

      assert_patch(show_live, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ "Tenant updated successfully"
      assert html =~ "some updated name"
    end

    test "updates tenant without inserting websms token, keeps old websms token", %{
      conn: conn,
      tenant: tenant
    } do
      {:ok, show_live, _html} = live(conn, Routes.tenant_show_path(conn, :show, tenant))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.tenant_show_path(conn, :edit, tenant))

      assert show_live
             |> form("#tenant-form",
               tenant:
                 Map.drop(@update_attrs, [
                   :outgoing_sms_configuration,
                   :outgoing_sms_configuration_type,
                   :outgoing_mail_configuration,
                   :outgoing_mail_configuration_type,
                   :from_email
                 ])
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 Map.drop(@update_attrs, [
                   :outgoing_sms_configuration,
                   :outgoing_mail_configuration
                 ])
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 update_in(@update_attrs, [:outgoing_mail_configuration], &Map.drop(&1, [:relay]))
             )
             |> render_change()

      assert show_live
             |> form("#tenant-form",
               tenant:
                 update_in(
                   @update_attrs,
                   [:outgoing_mail_configuration, :relay],
                   &Map.drop(&1, [:password])
                 )
             )
             |> render_change()

      assert html =
               show_live
               |> form("#tenant-form", tenant: @update_attrs)
               |> render_submit()

      assert_patch(show_live, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ "Tenant updated successfully"

      assert show_live |> element("a", "Edit") |> render_click()

      assert html =
               show_live
               |> form("#tenant-form",
                 tenant:
                   @update_attrs
                   |> Map.drop([:outgoing_mail_configuration, :outgoing_mail_configuration_type])
                   |> update_in(
                     [:outgoing_sms_configuration],
                     &Map.drop(&1, [:access_token])
                   )
               )
               |> render_submit()

      assert_patch(show_live, Routes.tenant_show_path(conn, :show, tenant))

      assert html =~ "Tenant updated successfully"

      assert [%Tenant{outgoing_sms_configuration: %{access_token: "test1111"}}] =
               TenantContext.list_tenants()
    end
  end
end
