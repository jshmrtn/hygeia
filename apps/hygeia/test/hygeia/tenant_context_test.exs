defmodule Hygeia.TenantContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.SedexExport
  alias Hygeia.TenantContext.Tenant

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "tenants" do
    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    test "list_tenants/0 returns all tenants" do
      tenant = tenant_fixture()
      assert TenantContext.list_tenants() == [tenant]
    end

    test "get_tenant!/1 returns the tenant with given uuid" do
      tenant = tenant_fixture()
      assert TenantContext.get_tenant!(tenant.uuid) == tenant
    end

    test "create_tenant/1 with valid data creates a tenant" do
      assert {:ok, %Tenant{} = tenant} = TenantContext.create_tenant(@valid_attrs)
      assert tenant.name == "some name"
    end

    test "create_tenant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = TenantContext.create_tenant(@invalid_attrs)
    end

    test "update_tenant/2 with valid data updates the tenant" do
      tenant = tenant_fixture()
      assert {:ok, %Tenant{} = tenant} = TenantContext.update_tenant(tenant, @update_attrs)
      assert tenant.name == "some updated name"
    end

    test "update_tenant/2 with invalid data returns error changeset" do
      tenant = tenant_fixture()
      assert {:error, %Ecto.Changeset{}} = TenantContext.update_tenant(tenant, @invalid_attrs)
      assert tenant == TenantContext.get_tenant!(tenant.uuid)
    end

    test "delete_tenant/1 deletes the tenant" do
      tenant = tenant_fixture()
      assert {:ok, %Tenant{}} = TenantContext.delete_tenant(tenant)
      assert_raise Ecto.NoResultsError, fn -> TenantContext.get_tenant!(tenant.uuid) end
    end

    test "change_tenant/1 returns a tenant changeset" do
      tenant = tenant_fixture()
      assert %Ecto.Changeset{} = TenantContext.change_tenant(tenant)
    end

    test "tenant_has_outgoing_mail_configuration?/1 returns false" do
      tenant =
        tenant_fixture(%{
          name: "Kanton",
          outgoing_mail_configuration: nil
        })

      refute TenantContext.tenant_has_outgoing_mail_configuration?(tenant)
    end

    test "tenant_has_outgoing_mail_configuration?/1 returns true" do
      tenant =
        tenant_fixture(%{
          name: "Kanton",
          iam_domain: "test",
          outgoing_mail_configuration: %{
            __type__: "smtp",
            server: "kanton.com",
            port: 2525,
            from_email: "info@kanton.com",
            username: "test1",
            password: "test1"
          }
        })

      assert TenantContext.tenant_has_outgoing_mail_configuration?(tenant)
    end
  end

  describe "sedex_exports" do
    @valid_attrs %{scheduling_date: ~N[2010-04-17 14:00:00], status: :sent}
    @update_attrs %{scheduling_date: ~N[2011-05-18 15:01:01], status: :error}
    @invalid_attrs %{scheduling_date: nil, status: nil}

    test "list_sedex_exports/0 returns all sedex_exports" do
      sedex_export = sedex_export_fixture()
      assert TenantContext.list_sedex_exports() == [sedex_export]
    end

    test "get_sedex_export!/1 returns the sedex_export with given id" do
      sedex_export = sedex_export_fixture()
      assert TenantContext.get_sedex_export!(sedex_export.uuid) == sedex_export
    end

    test "create_sedex_export/1 with valid data creates a sedex_export" do
      assert {:ok, %SedexExport{} = sedex_export} =
               TenantContext.create_sedex_export(tenant_fixture(), @valid_attrs)

      assert sedex_export.scheduling_date == ~N[2010-04-17 14:00:00]
      assert sedex_export.status == :sent
    end

    test "create_sedex_export/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               TenantContext.create_sedex_export(tenant_fixture(), @invalid_attrs)
    end

    test "update_sedex_export/2 with valid data updates the sedex_export" do
      sedex_export = sedex_export_fixture()

      assert {:ok, %SedexExport{} = sedex_export} =
               TenantContext.update_sedex_export(sedex_export, @update_attrs)

      assert sedex_export.scheduling_date == ~N[2011-05-18 15:01:01]
      assert sedex_export.status == :error
    end

    test "update_sedex_export/2 with invalid data returns error changeset" do
      sedex_export = sedex_export_fixture()

      assert {:error, %Ecto.Changeset{}} =
               TenantContext.update_sedex_export(sedex_export, @invalid_attrs)

      assert sedex_export == TenantContext.get_sedex_export!(sedex_export.uuid)
    end

    test "delete_sedex_export/1 deletes the sedex_export" do
      sedex_export = sedex_export_fixture()
      assert {:ok, %SedexExport{}} = TenantContext.delete_sedex_export(sedex_export)

      assert_raise Ecto.NoResultsError, fn ->
        TenantContext.get_sedex_export!(sedex_export.uuid)
      end
    end

    test "change_sedex_export/1 returns a sedex_export changeset" do
      sedex_export = sedex_export_fixture()
      assert %Ecto.Changeset{} = TenantContext.change_sedex_export(sedex_export)
    end
  end
end
