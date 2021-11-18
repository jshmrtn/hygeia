defmodule Hygeia.AutoTracingContext.AutoTracing.Occupation do
  @moduledoc "Occupation Schema"

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          related_visit_uuid: Ecto.UUID.t() | nil,
          related_visit: Ecto.Schema.belongs_to(Visit.t()) | nil,
          not_found: boolean() | nil,
          known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_not_found: boolean() | nil,
          known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          related_visit_uuid: Ecto.UUID.t() | nil,
          related_visit: Ecto.Schema.belongs_to(Visit.t()) | nil,
          not_found: boolean() | nil,
          known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_not_found: boolean() | nil,
          known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil
        }

  embedded_schema do
    field :kind, Kind
    field :kind_other, :string

    belongs_to :related_visit, Visit,
      foreign_key: :related_visit_uuid,
      references: :uuid

    belongs_to :known_organisation, Organisation,
      foreign_key: :known_organisation_uuid,
      references: :uuid

    field :not_found, :boolean, default: false

    embeds_one :unknown_organisation, Entity, on_replace: :delete

    belongs_to :known_division, Division,
      foreign_key: :known_division_uuid,
      references: :uuid

    field :division_not_found, :boolean, default: false

    embeds_one :unknown_division, Entity, on_replace: :delete
  end

  @spec changeset(schema :: t | empty, attrs :: map()) ::
          Ecto.Changeset.t(t)
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :uuid,
      :kind,
      :kind_other,
      :not_found,
      :known_organisation_uuid,
      :related_visit_uuid,
      :division_not_found,
      :known_division_uuid
    ])
    |> fill_uuid()
    |> validate_required([:kind])
    |> validate_kind_other()
    |> validate_organisation()
    |> validate_division()
  end

  defp validate_organisation(changeset) do
    changeset
    |> fetch_field!(:not_found)
    |> case do
      true ->
        changeset
        |> cast_embed(:unknown_organisation,
          required: true,
          with: &Entity.changeset(&1, &2, %{name_required: true, address_required: true})
        )
        |> put_change(:known_organisation_uuid, nil)
        |> put_change(:division_not_found, true)

      _else ->
        changeset
        |> fetch_field!(:known_organisation_uuid)
        |> case do
          nil -> add_error(changeset, :known_organisation_uuid, dgettext("errors", "is required"))
          _else -> changeset
        end
        |> put_embed(:unknown_organisation, nil)
    end
  end

  defp validate_kind_other(changeset) do
    changeset
    |> fetch_field!(:kind)
    |> case do
      :other -> validate_required(changeset, :kind_other)
      _defined -> put_change(changeset, :kind_other, nil)
    end
  end

  defp validate_division(changeset) do
    changeset
    |> fetch_field!(:division_not_found)
    |> case do
      true ->
        changeset
        |> cast_embed(:unknown_division)
        |> put_change(:known_division_uuid, nil)

      _else ->
        put_embed(changeset, :unknown_division, nil)
    end
  end
end
