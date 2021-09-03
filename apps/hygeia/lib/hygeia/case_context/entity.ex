defmodule Hygeia.CaseContext.Entity do
  @moduledoc """
  Model for Entity Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type empty :: %__MODULE__{
          name: String.t() | nil,
          division: String.t() | nil,
          person_first_name: String.t() | nil,
          person_last_name: String.t() | nil,
          address: Address.t() | nil
        }

  @type t :: %__MODULE__{
          name: String.t() | nil,
          division: String.t() | nil,
          person_first_name: String.t() | nil,
          person_last_name: String.t() | nil,
          address: Address.t()
        }

  @type changeset_options :: %{
          optional(:name_required) => boolean,
          optional(:address_required) => boolean
        }

  embedded_schema do
    field :name, :string
    field :division, :string
    field :person_first_name, :string
    field :person_last_name, :string

    embeds_one :address, Address, on_replace: :delete
  end

  @doc false
  @spec changeset(
          entity :: t | empty,
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: changeset_options
        ) :: Changeset.t()
  def changeset(entity, attrs \\ %{}, changeset_options \\ %{})

  def changeset(entity, attrs, %{name_required: true} = changeset_options) do
    entity
    |> changeset(attrs, %{changeset_options | name_required: false})
    |> validate_required([:name])
  end

  def changeset(entity, attrs, %{address_required: true} = changeset_options) do
    entity
    |> changeset(attrs, %{changeset_options | address_required: false})
    |> cast_embed(:address, with: &Address.changeset(&1, &2, %{required: true}), required: true)
    |> validate_embed_required(:address, Address)
  end

  def changeset(entity, attrs, _changeset_options) do
    entity
    |> cast(attrs, [:uuid, :name, :division, :person_first_name, :person_last_name])
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
