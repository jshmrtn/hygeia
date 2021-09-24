defmodule Hygeia.AutoTracingContext.AutoTracing.SchoolVisit do
  @moduledoc "Module responsible for tracking school visits within the auto tracing context."

  use Hygeia, :model

  alias Hygeia.AutoTracingContext.AutoTracing.SchoolVisit.Reason
  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Organisation

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          is_occupied: boolean() | nil,
          visit_reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          visited_at: Date.t() | nil,
          not_found: boolean() | nil,
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          is_occupied: boolean() | nil,
          visit_reason: Reason.t() | nil,
          other_reason: String.t() | nil,
          visited_at: Date.t() | nil,
          not_found: boolean() | nil,
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil
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
      :known_school_uuid
    ])
    |> fill_uuid()
    |> validate_required([:visit_reason, :visited_at])
    |> validate_occupied()
    |> validate_other_reason()
    |> validate_existent_school()
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

  defp validate_existent_school(changeset) do
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

      _else ->
        changeset
        |> validate_required(:known_school_uuid)
        |> put_change(:unknown_school, nil)
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
end
