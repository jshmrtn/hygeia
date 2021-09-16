defmodule Hygeia.AutoTracingContext.AutoTracing.SchoolVisit do
  @moduledoc false

  use Hygeia, :model

  import EctoEnum

  import HygeiaGettext

  alias Hygeia.CaseContext.Entity
  alias Hygeia.OrganisationContext.Organisation

  defenum Reason, :school_visit_reason, [
    "student",
    "professor",
    "employee",
    "visitor"
  ]

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          visit_reason: Reason.t() | nil,
          not_found: boolean() | nil,
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          visit_reason: Reason.t() | nil,
          not_found: boolean() | nil,
          known_school: Ecto.Schema.belongs_to(Organisation.t()) | nil,
          unknown_school: Entity.t() | nil
        }

  embedded_schema do
    field :visit_reason, Reason

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
      :visit_reason,
      :not_found,
      :known_school_uuid
    ])
    |> fill_uuid()
    |> validate_required([:visit_reason])
    |> validate_existent_school()
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

  @spec visit_reason :: [{String.t(), Reason.t()}]
  def visit_reason,
    do:
      Enum.map(
        Reason.__enum_map__(),
        &{visit_reason_translation(&1), &1}
      )

  @spec visit_reason_translation(type :: Reason.t()) :: String.t()
  def visit_reason_translation(:student), do: pgettext("School visit reason", "Student")
  def visit_reason_translation(:professor), do: pgettext("School visit reason", "Professor")
  def visit_reason_translation(:employee), do: pgettext("School visit reason", "Employee")
  def visit_reason_translation(:visitor), do: pgettext("School visit reason", "Visitor ")
end
