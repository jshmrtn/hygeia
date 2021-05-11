defmodule Hygeia.CaseContext.Hospitalization do
  @moduledoc """
  Model for Hospitalization Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.OrganisationContext.Organisation

  @type empty :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "hospitalizations" do
    field :start, :date
    field :end, :date

    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid
    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @doc false
  @spec changeset(hospitalization :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(hospitalization, attrs) do
    hospitalization
    |> cast(attrs, [:uuid, :start, :end, :organisation_uuid, :case_uuid])
    |> fill_uuid
    |> validate_required([])
  end
end
