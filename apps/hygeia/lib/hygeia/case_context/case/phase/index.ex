defmodule Hygeia.CaseContext.Case.Phase.Index do
  @moduledoc """
  Model for Phase / Index Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum EndReason, :case_phase_index_end_reason, [
    "healed",
    "death",
    "no_follow_up",
    "other"
  ]

  @type empty :: %__MODULE__{
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil
        }

  @type t :: %__MODULE__{
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil
        }

  embedded_schema do
    field :end_reason, EndReason
    field :other_end_reason, :string
  end

  @spec changeset(index :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(index, attrs) do
    index
    |> cast(attrs, [:end_reason, :other_end_reason])
    |> validate_end_reason_other()
  end

  defp validate_end_reason_other(changeset) do
    changeset
    |> fetch_field!(:end_reason)
    |> case do
      :other -> validate_required(changeset, [:other_end_reason])
      _defined -> put_change(changeset, :other_end_reason, nil)
    end
  end

  # Fix for polymorphic embed inside embed
  defimpl Jason.Encoder do
    @spec encode(Hygeia.CaseContext.Case.Phase.Index.t(), Jason.Encoder.opts()) :: iodata()
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.put(:__type__, "index")
      |> Jason.Encode.map(opts)
    end
  end
end
