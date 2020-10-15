defmodule Hygeia.CaseContext.Address do
  @moduledoc """
  Model for Address Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: String.t() | nil
        }

  @type t :: %__MODULE__{
          address: String.t() | nil,
          zip: String.t() | nil,
          place: String.t() | nil,
          subdivision: String.t() | nil,
          country: String.t() | nil
        }

  embedded_schema do
    field :address, :string
    field :zip, :string
    field :place, :string
    field :subdivision, :string
    field :country, :string, default: "CH"
  end

  @doc false
  @spec changeset(address :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:address, :zip, :place, :subdivision, :country])
    |> validate_required([])
    |> validate_country(:country)
    |> validate_subdivision(:subdivision, :country)
  end
end
