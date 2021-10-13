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
          address: Address.t() | nil,
          different_location: boolean() | nil
        }

  @type t :: %__MODULE__{
          first_contact: Date.t() | nil,
          location: IsolationLocation.t() | nil,
          location_details: String.t() | nil,
          address: Address.t() | nil,
          different_location: boolean()
        }

  embedded_schema do
    field :first_contact, :date
    field :location, IsolationLocation
    field :location_details, :string
    field :different_location, :boolean, default: false

    embeds_one :address, Address, on_replace: :update
  end

  @doc false
  @spec changeset(monitoring :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(monitoring, attrs) do
    monitoring
    |> cast(attrs, [:first_contact, :location, :location_details, :different_location])
    |> validate_different_location()
  end

  defp validate_different_location(changeset) do
    changeset
    |> fetch_field!(:different_location)
    |> case do
      true ->
        changeset
        |> validate_required([:location, :location_details])
        |> cast_embed(:address,
          with: &Address.changeset(&1, &2, %{required: true}),
          required: true
        )
        |> validate_embed_required(:address, Address)

      _else ->
        changeset
        |> put_change(:location, nil)
        |> put_change(:location_details, nil)
        |> put_change(:address, nil)
    end
  end
end
