defmodule Hygeia.CaseContext.Transmission.InfectionPlace do
  @moduledoc """
  Model for InfectionPlace Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.InfectionPlaceType

  @type empty :: %__MODULE__{
          address: Address.t() | nil,
          known: boolean() | nil,
          activity_mapping_executed: boolean() | nil,
          activity_mapping: String.t() | nil,
          type: Ecto.Schema.belongs_to(InfectionPlaceType.t()) | nil,
          type_uuid: String.t() | nil,
          name: String.t() | nil,
          flight_information: String.t() | nil
        }

  @type t :: empty

  embedded_schema do
    field :known, :boolean, default: false
    field :activity_mapping_executed, :boolean, default: false
    field :activity_mapping, :string
    field :name, :string
    field :flight_information, :string

    embeds_one :address, Address, on_replace: :update

    belongs_to :type, InfectionPlaceType, references: :uuid, foreign_key: :type_uuid
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
      :type_uuid,
      :name,
      :flight_information
    ])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
