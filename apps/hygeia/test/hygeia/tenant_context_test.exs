defmodule Hygeia.TenantContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.TenantContext
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
end
