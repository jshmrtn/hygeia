defmodule Hygeia.CaseContext.Case.Employer do
  @moduledoc """
  Model for Employer Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type empty :: %__MODULE__{
          name: String.t() | nil,
          address: Address.t() | nil
        }

  @type t :: %__MODULE__{
          name: String.t() | nil,
          address: Address.t()
        }

  embedded_schema do
    field :name, :string

    embeds_one :address, Address, on_replace: :delete
  end

  @doc false
  @spec changeset(employer :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(employer, attrs) do
    employer
    |> cast(attrs, [:name])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
