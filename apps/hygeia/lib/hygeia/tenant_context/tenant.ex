defmodule Hygeia.TenantContext.Tenant do
  @moduledoc """
  Model for Tenants
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          people: Ecto.Schema.has_many(Person.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          people: Ecto.Schema.has_many(Person.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "tenants" do
    field :name, :string

    has_many :people, Person

    timestamps()
  end

  @doc false
  @spec changeset(tenant :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
