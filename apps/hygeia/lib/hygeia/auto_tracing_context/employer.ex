defmodule Hygeia.AutoTracingContext.Employer do
  @moduledoc """
  Employer Model
  """
  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type t :: %__MODULE__{
          name: String.t() | nil,
          address: Address.t() | nil
        }

  @type empty :: %__MODULE__{
          name: String.t() | nil,
          address: Address.t() | nil
        }

  embedded_schema do
    field :name, :string

    embeds_one :address, Address
  end

  @spec changeset(employer :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(employer, attrs) do
    employer
    |> cast(attrs, [:name])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
