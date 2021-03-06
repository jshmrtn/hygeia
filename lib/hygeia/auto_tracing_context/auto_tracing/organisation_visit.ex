defmodule Hygeia.AutoTracingContext.AutoTracing.OrganisationVisit do
  @moduledoc "Module responsible for tracking school visits within the auto tracing context."

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Visit.Reason

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          is_occupied: boolean() | nil,
          visit_reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          visited_at: Date.t() | nil,
          not_found: boolean() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_not_found: boolean() | nil,
          known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          is_occupied: boolean() | nil,
          visit_reason: Reason.t(),
          other_reason: String.t() | nil,
          visited_at: Date.t(),
          not_found: boolean() | nil,
          organisation: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_organisation: Entity.t() | nil,
          division_not_found: boolean() | nil,
          known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil
        }

  embedded_schema do
    field :is_occupied, :boolean
    field :visit_reason, Reason
    field :other_reason, :string
    field :visited_at, :date

    belongs_to :organisation, Organisation,
      foreign_key: :organisation_uuid,
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
      :is_occupied,
      :visit_reason,
      :other_reason,
      :visited_at,
      :not_found,
      :organisation_uuid,
      :division_not_found,
      :known_division_uuid
    ])
    |> fill_uuid()
    |> validate_required([:visit_reason, :visited_at])
    |> validate_past_date(:visited_at)
    |> validate_occupied()
    |> validate_other_reason()
    |> validate_organisation()
    |> validate_division()
  end

  defp validate_occupied(changeset) do
    changeset
    |> fetch_field!(:visit_reason)
    |> case do
      reason when reason in [:student, :professor, :employee] ->
        validate_required(changeset, [:is_occupied])

      _other ->
        put_change(changeset, :is_occupied, nil)
    end
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
        |> put_change(:organisation_uuid, nil)
        |> put_change(:division_not_found, true)

      _else ->
        changeset
        |> fetch_field!(:organisation_uuid)
        |> case do
          nil -> add_error(changeset, :organisation_uuid, dgettext("errors", "is required"))
          _else -> changeset
        end
        |> put_embed(:unknown_organisation, nil)
    end
  end

  defp validate_other_reason(changeset) do
    changeset
    |> fetch_field!(:visit_reason)
    |> case do
      :other -> validate_required(changeset, [:other_reason])
      _defined -> put_change(changeset, :other_reason, nil)
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
