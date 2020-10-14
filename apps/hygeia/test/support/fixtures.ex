defmodule Hygeia.Fixtures do
  @moduledoc """
  Model Fixtures Helper
  """

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext
  alias Hygeia.UserContext.User

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

  @valid_attrs %{
    display_name: "Wilfred Walrus",
    email: "wilfred.walrus@example.com",
    iam_sub: "8fe86005-b3c6-4d7c-9746-53e090d05e48"
  }

  @spec user_fixture(attrs :: Hygeia.ecto_changeset_params()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@valid_attrs)
      |> UserContext.create_user()

    user
  end
end
