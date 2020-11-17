defmodule Hygeia.CaseContext.Case.Phase.PossibleIndex do
  @moduledoc """
  Model for Phase / PossibleIndex Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum Type, :case_phase_possible_index_type, ["contact_person", "travel"]

  defenum EndReason, :case_phase_possible_index_end_reason, [
    "asymptomatic",
    "converted_to_index",
    "no_follow_up",
    "other"
  ]

  @type empty :: %__MODULE__{
          type: Type.t() | nil,
          end_reason: EndReason.t() | nil
        }

  @type t :: %__MODULE__{
          type: Type.t(),
          end_reason: EndReason.t() | nil
        }

  embedded_schema do
    field :type, Type
    field :end_reason, EndReason
  end

  @doc false
  @spec changeset(possible_index :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(possible_index, attrs) do
    possible_index
    |> cast(attrs, [:type, :end_reason])
    |> validate_required([:type])
  end

  # Fix for polymorphic embed inside embed
  defimpl Jason.Encoder do
    @spec encode(Hygeia.CaseContext.Case.Phase.PossibleIndex.t(), Jason.Encoder.opts()) ::
            iodata()
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.put(:__type__, "possible_index")
      |> Jason.Encode.map(opts)
    end
  end
end
