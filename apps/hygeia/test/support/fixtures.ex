defmodule Hygeia.Fixtures do
  @moduledoc """
  Model Fixtures Helper
  """

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @valid_attrs %{name: "some name"}

  @spec tenant_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Tenant.t()
  def tenant_fixture(attrs \\ %{}) do
    {:ok, tenant} =
      attrs
      |> Enum.into(@valid_attrs)
      |> TenantContext.create_tenant()

    tenant
  end

  @valid_attrs %{name: "some name"}

  @spec profession_fixture(attrs :: Hygeia.ecto_changeset_params()) :: Profession.t()
  def profession_fixture(attrs \\ %{}) do
    {:ok, profession} =
      attrs
      |> Enum.into(@valid_attrs)
      |> CaseContext.create_profession()

    profession
  end
end
