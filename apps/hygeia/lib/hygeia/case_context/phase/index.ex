defmodule Hygeia.CaseContext.Phase.Index do
  @moduledoc """
  Model for Phase / Index Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum EndReason, :case_phase_index_end_reason, [
    "healed",
    "death",
    "no_follow_up"
  ]

  @type empty :: %__MODULE__{
          end_reason: EndReason.t() | nil
        }

  @type t :: %__MODULE__{
          end_reason: EndReason.t() | nil
        }

  embedded_schema do
    field :end_reason, EndReason
  end

  @doc false
  @spec changeset(index :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(index, attrs) do
    cast(index, attrs, [:end_reason])
  end

  # Fix for polymorphic embed inside embed
  defimpl Jason.Encoder do
    @spec encode(Hygeia.CaseContext.Phase.Index.t(), Jason.Encoder.opts()) :: iodata()
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.put(:__type__, "index")
      |> Jason.Encode.map(opts)
    end
  end
end
