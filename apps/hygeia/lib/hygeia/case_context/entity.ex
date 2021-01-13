defmodule Hygeia.CaseContext.Entity do
  @moduledoc """
  Model for Entity Schema
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
  @spec changeset(entity :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [:uuid, :name])
    |> fill_uuid
    |> validate_required([])
    |> cast_embed(:address)
  end

  @spec merge(old :: t() | Changeset.t(t()), new :: t() | Changeset.t(t())) :: Changeset.t(t())
  def merge(old, new) do
    merge(old, new, __MODULE__, fn embed, old_embed, new_embed when embed in [:address] ->
      Address.merge(old_embed, new_embed)
    end)
  end
end
