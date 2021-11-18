defmodule Hygeia.OrganisationContext.Visit do
  @moduledoc """
  Model for Visits
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit.Reason


  @type empty :: %__MODULE__{
    visit_reason: Reason.t() | nil,
    other_reason: String.t() | nil,
    last_visit_at: DateTime.t() | nil,
    known_organisation_uuid: Ecto.UUID.t() | nil,
    known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
    unknown_organisation: Entity.t() | nil,
    known_division_uuid: Ecto.UUID.t() | nil,
    known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
    unknown_division: Entity.t() | nil,
    affiliation: Ecto.Schema.has_many(Affiliation.t()),
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

@type t :: %__MODULE__{
    visit_reason: Reason.t() | nil,
    other_reason: String.t() | nil,
    last_visit_at: DateTime.t() | nil,
    known_organisation_uuid: Ecto.UUID.t() | nil,
    known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
    unknown_organisation: Entity.t() | nil,
    known_division_uuid: Ecto.UUID.t() | nil,
    known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
    unknown_division: Entity.t() | nil,
    affiliation: Ecto.Schema.has_one(Affiliation.t()),
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  schema "visits" do
    field :visit_reason, Reason
    field :other_reason, :string
    field :last_visit_at, :utc_datetime

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :known_organisation, Organisation,
      foreign_key: :known_organisation_uuid,
      references: :uuid

    embeds_one :unknown_organisation, Entity, on_replace: :delete

    belongs_to :known_division, Division,
      foreign_key: :known_division_uuid,
      references: :uuid

    embeds_one :unknown_division, Entity, on_replace: :delete

    has_one :affiliation, Affiliation, foreign_key: :related_visit_uuid, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :reason,
      :other_reason,
      :last_visit_at,
      :person_uuid,
      :known_organisation_uuid,
      :known_division_uuid
    ])
    |> validate_required([:visit_reason])
    |> validate_other_reason()
  end

  defp validate_other_reason(changeset) do
    changeset
    |> fetch_field!(:visit_reason)
    |> case do
      :other -> validate_required(changeset, [:other_reason])
      _defined -> put_change(changeset, :other_reason, nil)
    end
  end
end
