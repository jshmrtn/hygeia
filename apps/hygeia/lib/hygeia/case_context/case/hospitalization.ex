defmodule Hygeia.CaseContext.Case.Hospitalization do
  @moduledoc """
  Model for Hospitalization Schema
  """

  use Hygeia, :model

  alias Hygeia.OrganisationContext.Organisation

  @type empty :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil
        }

  @type t :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          organisation_uuid: Ecto.UUID.t() | nil
        }

  embedded_schema do
    field :start, :date
    field :end, :date
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid
  end

  @doc false
  @spec changeset(hospitalization :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(hospitalization, attrs) do
    hospitalization
    |> cast(attrs, [:uuid, :start, :end, :organisation_uuid])
    |> fill_uuid
    |> validate_required([])
  end
end
