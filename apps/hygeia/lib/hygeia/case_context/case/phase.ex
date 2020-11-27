defmodule Hygeia.CaseContext.Case.Phase do
  @moduledoc """
  Model for Phase Schema
  """

  use Hygeia, :model

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Phase.Index
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex

  @type empty :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          details: Index.t() | PossibleIndex.t() | nil
        }

  @type t :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil,
          details: Index.t() | PossibleIndex.t()
        }

  embedded_schema do
    field :start, :date
    field :end, :date

    field :details, PolymorphicEmbed,
      types: [
        index: Index,
        possible_index: PossibleIndex
      ]
  end

  @doc false
  @spec changeset(phase :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(phase, attrs) do
    phase
    |> cast(attrs, [:start, :end])
    |> cast_polymorphic_embed(:details)
    |> validate_required([:details])
    |> validate_date_relative(
      :start,
      [:lt, :eq],
      :end,
      dgettext("errors", "start must be before end")
    )
    |> validate_date_relative(
      :end,
      [:gt, :eq],
      :start,
      dgettext("errors", "end must be after start")
    )
  end

  defp validate_date_relative(changeset, field, cmp_equality, cmp_field, message) do
    case get_field(changeset, cmp_field) do
      nil ->
        changeset

      cmp_value ->
        validate_change(changeset, field, fn
          ^field, nil ->
            []

          ^field, value ->
            if Date.compare(value, cmp_value) in cmp_equality do
              []
            else
              [{field, message}]
            end
        end)
    end
  end
end
