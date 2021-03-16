defmodule Hygeia.CaseContext.Case.Phase.PossibleIndex do
  @moduledoc """
  Model for Phase / PossibleIndex Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum Type, :case_phase_possible_index_type, [
    "contact_person",
    "travel",
    "outbreak",
    "covid_app",
    "other"
  ]

  defenum EndReason, :case_phase_possible_index_end_reason, [
    "asymptomatic",
    "converted_to_index",
    "no_follow_up",
    "negative_test",
    "other"
  ]

  @type empty :: %__MODULE__{
          type: Type.t() | nil,
          type_other: String.t() | nil,
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil
        }

  @type t :: %__MODULE__{
          type: Type.t(),
          type_other: String.t() | nil,
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil
        }

  embedded_schema do
    field :type, Type
    field :type_other, :string
    field :end_reason, EndReason
    field :other_end_reason, :string
  end

  @spec changeset(possible_index :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(possible_index, attrs) do
    possible_index
    |> cast(attrs, [:type, :type_other, :end_reason, :other_end_reason])
    |> validate_required([:type])
    |> validate_type_other()
    |> validate_end_reason_other()
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
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
