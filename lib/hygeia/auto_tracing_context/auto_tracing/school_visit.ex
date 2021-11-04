defmodule Hygeia.AutoTracingContext.AutoTracing.SchoolVisit do
  @moduledoc "Module responsible for tracking school visits within the auto tracing context."

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.AutoTracingContext.AutoTracing.SchoolVisit.Reason
  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          is_occupied: boolean() | nil,
          visit_reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          visited_at: Date.t() | nil,
          not_found: boolean() | nil,
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil,
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
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil,
          division_not_found: boolean() | nil,
          known_division: Ecto.Schema.belongs_to(Division.t()) | nil,
          unknown_division: Entity.t() | nil
        }

  embedded_schema do
    field :is_occupied, :boolean
    field :visit_reason, Reason
    field :other_reason, :string
    field :visited_at, :date

    belongs_to :known_school, Organisation,
      foreign_key: :known_school_uuid,
      references: :uuid

    field :not_found, :boolean, default: false

    embeds_one :unknown_school, Entity, on_replace: :delete

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
      :known_school_uuid,
      :division_not_found,
      :known_division_uuid
    ])
    |> fill_uuid()
    |> validate_required([:visit_reason, :visited_at])
    |> validate_occupied()
    |> validate_other_reason()
    |> validate_school()
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

  defp validate_school(changeset) do
    changeset
    |> fetch_field!(:not_found)
    |> case do
      true ->
        changeset
        |> cast_embed(:unknown_school,
          required: true,
          with: &Entity.changeset(&1, &2, %{name_required: true, address_required: true})
        )
        |> put_change(:known_school_uuid, nil)
        |> put_change(:division_not_found, true)

      _else ->
        changeset
        |> fetch_field!(:known_school_uuid)
        |> case do
          nil -> add_error(changeset, :known_school_uuid, dgettext("errors", "is required"))
          _else -> changeset
        end
        |> put_embed(:unknown_school, nil)
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
