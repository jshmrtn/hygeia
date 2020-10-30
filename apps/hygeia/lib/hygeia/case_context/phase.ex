defmodule Hygeia.CaseContext.Phase do
  @moduledoc """
  Model for Phase Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum EndReason, :isolation_location, [
    "healed",
    "death",
    "no_follow_up",
    "asymptomatic",
    "converted_to_index",
    "other"
  ]

  defenum Type, :phase_type, [
    "index",
    "possible_index"
  ]

  @type empty :: %__MODULE__{
          type: Type.t() | nil,
          start: Date.t() | nil,
          end: Date.t() | nil,
          end_reason: EndReason.t() | nil
        }

  @type t :: %__MODULE__{
          type: Type.t(),
          start: Date.t() | nil,
          end: Date.t() | nil,
          end_reason: EndReason.t() | nil
        }

  embedded_schema do
    field :type, Type
    field :start, :date
    field :end, :date
    field :end_reason, EndReason
  end

  @doc false
  @spec changeset(phase :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(phase, attrs) do
    phase
    |> cast(attrs, [:type, :start, :end, :end_reason])
    |> validate_required([:type])
  end
end
