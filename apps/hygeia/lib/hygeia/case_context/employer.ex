defmodule Hygeia.CaseContext.Employer do
  @moduledoc """
  Model for Employer Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type empty :: %__MODULE__{
          name: String.t() | nil,
          supervisor_name: String.t() | nil,
          supervisor_phone: String.t() | nil,
          address: Address.t() | nil
        }

  @type t :: %__MODULE__{
          name: String.t() | nil,
          supervisor_name: String.t() | nil,
          supervisor_phone: String.t() | nil,
          address: Address.t()
        }

  embedded_schema do
    field :name, :string
    field :supervisor_name, :string
    field :supervisor_phone, :string

    embeds_one :address, Address, on_replace: :delete
  end

  @doc false
  @spec changeset(employer :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(employer, attrs) do
    employer
    |> cast(attrs, [:uuid, :name, :supervisor_name, :supervisor_phone])
    |> fill_uuid
    |> validate_required([])
    |> cast_embed(:address)
    |> validate_and_normalize_phone(:supervisor_phone)
  end
end
