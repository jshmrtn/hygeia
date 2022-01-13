defmodule Hygeia.CaseContext.Case.Phase.PossibleIndex do
  @moduledoc """
  Model for Phase / PossibleIndex Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type

  @type empty :: %__MODULE__{
          type: Type.t() | nil,
          type_other: String.t() | nil,
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil,
          end_reason_date: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          type: Type.t(),
          type_other: String.t() | nil,
          end_reason: EndReason.t() | nil,
          other_end_reason: String.t() | nil,
          end_reason_date: DateTime.t() | nil
        }

  embedded_schema do
    field :type, Type
    field :type_other, :string
    field :end_reason, EndReason
    field :other_end_reason, :string
    field :end_reason_date, :utc_datetime_usec
  end

  @spec changeset(possible_index :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(possible_index, attrs) do
    possible_index
    |> cast(attrs, [:type, :type_other, :end_reason, :other_end_reason, :end_reason_date])
    |> validate_required([:type])
    |> validate_type_other()
    |> validate_end_reason_other()
    |> set_end_reason_date()
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

  defp set_end_reason_date(changeset) do
    case fetch_change(changeset, :end_reason) do
      {:ok, nil} -> put_change(changeset, :end_reason_date, nil)
      {:ok, _end_reason_change} -> put_change(changeset, :end_reason_date, DateTime.utc_now())
      :error -> changeset
    end
  end

  @doc """
  Default Phase Length in days

  This includes the start date, so always the regulated amount of days - 1.
  """
  @spec default_length_days :: pos_integer()
  def default_length_days, do: 4

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
