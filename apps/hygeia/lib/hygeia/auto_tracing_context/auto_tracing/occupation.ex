defmodule Hygeia.AutoTracingContext.AutoTracing.Occupation do
  @moduledoc "Occupation Schema"

  use Hygeia, :model

  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Organisation

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          kind: Kind.t() | nil,
          kind_other: String.t() | nil,
          known_organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil
        }

  embedded_schema do
    field :kind, Kind
    field :kind_other, :string

    belongs_to :known_organisation, Organisation,
      foreign_key: :known_organisation_uuid,
      references: :uuid

    field :not_found, :boolean, default: false

    embeds_one :unknown_organisation, Entity, on_replace: :delete
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
      :known_organisation_uuid
    ])
    |> fill_uuid()
    |> validate_required([:kind])
    |> validate_kind_other()
    |> validate_existent_organisation()
  end

  defp validate_existent_organisation(changeset) do
    changeset
    |> fetch_field!(:not_found)
    |> case do
      true ->
        changeset
        |> cast_embed(:unknown_organisation, required: true)
        |> put_change(:known_organisation_uuid, nil)

      _else ->
        changeset
        |> validate_required(:known_organisation_uuid)
        |> put_embed(:unknown_organisation, nil)
    end
  end

  defp validate_kind_other(changeset) do
    changeset
    |> fetch_field!(:kind)
    |> case do
      :other -> validate_required(changeset, [:kind_other])
      _defined -> put_change(changeset, :kind_other, nil)
    end
  end
end
