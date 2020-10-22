defmodule Hygeia.OrganisationContext.Position do
  @moduledoc """
  Model for Positions
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext.Organisation

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          position: String.t() | nil,
          person_uuid: String.t() | nil,
          person: Ecto.Schema.belongs_to(Person.t()) | nil,
          organisation_uuid: String.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @type t :: %__MODULE__{
          uuid: String.t(),
          position: String.t(),
          person_uuid: String.t(),
          person: Ecto.Schema.belongs_to(Person.t()),
          organisation_uuid: String.t(),
          organisation: Ecto.Schema.belongs_to(Organisation.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "positions" do
    field :position, :string

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid

    timestamps()
  end

  @doc false
  @spec changeset(position :: empty | t, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t()
  def changeset(position, attrs) do
    position
    |> cast(attrs, [:position, :person_uuid, :organisation_uuid])
    |> validate_required([:position, :person_uuid, :organisation_uuid])
  end
end
