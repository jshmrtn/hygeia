defmodule Hygeia.CaseContext.Case.Monitoring do
  @moduledoc """
  Model for Monitoring Schema
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Address

  defenum IsolationLocation, :isolation_location, [
    "home",
    "social_medical_facility",
    "hospital",
    "hotel",
    "asylum_center",
    "other"
  ]

  @type empty :: %__MODULE__{
          first_contact: Date.t() | nil,
          location: IsolationLocation.t() | nil,
          location_details: String.t() | nil,
          address: Address.t() | nil
        }

  @type t :: %__MODULE__{
          first_contact: Date.t() | nil,
          location: IsolationLocation.t() | nil,
          location_details: String.t() | nil,
          address: Address.t() | nil
        }

  embedded_schema do
    field :first_contact, :date
    field :location, IsolationLocation
    field :location_details, :string

    embeds_one :address, Address, on_replace: :update
  end

  @doc false
  @spec changeset(clinical :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(clinical, attrs) do
    clinical
    |> cast(attrs, [:first_contact, :location, :location_details])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
