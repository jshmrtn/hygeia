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
    reason: Reason.t() | nil,
    other_reason: String.t() | nil,
    last_visit_at: Date.t() | nil,
    organisation_uuid: Ecto.UUID.t() | nil,
    organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
    unknown_organisation: Entity.t() | nil,
    division_uuid: Ecto.UUID.t() | nil,
    division: Ecto.Schema.belongs_to(Division.t()) | nil,
    unknown_division: Entity.t() | nil,
    affiliation: Ecto.Schema.has_many(Affiliation.t()),
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

@type t :: %__MODULE__{
    reason: Reason.t() | nil,
    other_reason: String.t() | nil,
    last_visit_at: Date.t() | nil,
    organisation_uuid: Ecto.UUID.t() | nil,
    organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
    unknown_organisation: Entity.t() | nil,
    division_uuid: Ecto.UUID.t() | nil,
    division: Ecto.Schema.belongs_to(Division.t()) | nil,
    unknown_division: Entity.t() | nil,
    affiliation: Ecto.Schema.has_one(Affiliation.t()),
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  schema "visits" do
    field :reason, Reason
    field :other_reason, :string
    field :last_visit_at, :date

    belongs_to :person, Person, references: :uuid, foreign_key: :person_uuid
    belongs_to :organisation, Organisation,
      foreign_key: :organisation_uuid,
      references: :uuid

    embeds_one :unknown_organisation, Entity, on_replace: :delete

    belongs_to :division, Division,
      foreign_key: :division_uuid,
      references: :uuid

    embeds_one :unknown_division, Entity, on_replace: :delete

    has_one :affiliation, Affiliation, foreign_key: :related_visit_uuid, on_replace: :update, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [
      :uuid,
      :reason,
      :other_reason,
      :last_visit_at,
      :person_uuid,
      :organisation_uuid,
      :division_uuid
    ])
    |> validate_required([:reason])
    |> validate_other_reason()
    |> validate_organisation()
    |> validate_unknown_organisation()
    |> validate_division()
    |> validate_unknown_division()
  end

  defp validate_other_reason(changeset) do
    changeset
    |> fetch_field!(:reason)
    |> case do
      :other -> validate_required(changeset, [:other_reason])
      _defined -> put_change(changeset, :other_reason, nil)
    end
  end

  defp validate_organisation(changeset) do
    changeset
    |> fetch_field!(:organisation_uuid)
    |> case do
      nil -> changeset
      _uuid -> put_embed(changeset, :unknown_organisation, nil)
    end
  end

  defp validate_unknown_organisation(changeset) do
    changeset
    |> fetch_field!(:unknown_organisation)
    |> case do
      nil -> changeset
      _uuid -> put_change(changeset, :organisation_uuid, nil)
    end
  end

  defp validate_division(changeset) do
    changeset
    |> fetch_field!(:division_uuid)
    |> case do
      nil -> changeset
      _else -> put_embed(changeset, :unknown_division, nil)
    end
  end

  defp validate_unknown_division(changeset) do
    changeset
    |> fetch_field!(:unknown_division)
    |> case do
      nil -> changeset
      _else -> put_change(changeset, :division_uuid, nil)
    end
  end
end
