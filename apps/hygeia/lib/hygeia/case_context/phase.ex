defmodule Hygeia.CaseContext.Phase do
  @moduledoc """
  Model for Phase Schema
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Phase.Index
  alias Hygeia.CaseContext.Phase.PossibleIndex

  defenum EndReason, :isolation_location, [
    "healed",
    "death",
    "no_follow_up",
    "asymptomatic",
    "converted_to_index",
    "other"
  ]

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
  end
end
