defmodule Hygeia.CaseContext.InfectionPlace do
  @moduledoc """
  Model for InfectionPlace Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type empty :: %__MODULE__{
          address: Address.t() | nil,
          known: boolean() | nil,
          activity_mapping_executed: boolean() | nil,
          activity_mapping: String.t() | nil,
          type: String.t() | nil,
          name: String.t() | nil,
          flight_information: String.t() | nil
        }

  @type t :: empty

  embedded_schema do
    field :known, :boolean
    field :activity_mapping_executed, :boolean
    field :activity_mapping, :string
    # TODO: Make place an enum / relation
    field :type, :string
    field :name, :string
    field :flight_information, :string

    embeds_one :address, Address
  end

  @doc false
  @spec changeset(infection_place :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(infection_place, attrs) do
    infection_place
    |> cast(attrs, [
      :known,
      :activity_mapping_executed,
      :activity_mapping,
      :type,
      :name,
      :flight_information
    ])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
