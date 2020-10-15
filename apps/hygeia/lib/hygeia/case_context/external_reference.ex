defmodule Hygeia.CaseContext.ExternalReference do
  @moduledoc """
  Model for External Reference Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum Type, :external_reference_type, ["ism", "other"]

  @type empty :: %__MODULE__{
          type: String.t() | nil,
          type_name: String.t() | nil,
          value: String.t() | nil
        }

  @type t :: %__MODULE__{
          type: String.t(),
          type_name: String.t(),
          value: String.t()
        }

  embedded_schema do
    field :type, Type
    field :type_name, :string
    field :value, :string
  end

  @doc false
  @spec changeset(external_reference :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(external_reference, attrs) do
    external_reference
    |> cast(attrs, [:type, :type_name, :value])
    |> validate_required([:type, :value])
    |> validate_other_type
  end

  defp validate_other_type(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_name])
      _type -> validate_inclusion(changeset, :type_name, [nil])
    end
  end
end
