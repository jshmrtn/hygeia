defmodule Hygeia.Fixtures do
  @moduledoc """
  Model Fixtures Helper
  """

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
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

  @valid_attrs %{
    address: %{
      address: "Neugasse 51",
      zip: "9000",
      place: "St. Gallen",
      subdivision: "SG",
      country: "CH"
    },
    birth_date: ~D[2010-04-17],
    contact_methods: [
      %{
        type: :mobile,
        value: "+41 78 724 57 90",
        comment: "Call only between 7 and 9 am"
      }
    ],
    employers: [
      %{
        name: "JOSHMARTIN GmbH",
        address: %{
          address: "Neugasse 51",
          zip: "9000",
          place: "St. Gallen",
          subdivision: "SG",
          country: "CH"
        }
      }
    ],
    external_references: [
      %{
        type: :ism,
        value: "7000"
      },
      %{
        type: :other,
        type_name: "foo",
        value: "7000"
      }
    ],
    first_name: "some first_name",
    last_name: "some last_name",
    sex: :female
  }

  @spec person_fixture(tenant :: Tenant.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Person.t()
  def person_fixture(tenant \\ tenant_fixture(), attrs \\ %{}) do
    {:ok, person} = CaseContext.create_person(tenant, Enum.into(attrs, @valid_attrs))

    person
  end
end
