defmodule Hygeia.CaseContext.Case.Monitoring do
  @moduledoc """
  Model for Monitoring Schema
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case.Monitoring.IsolationLocation

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
    |> validate_location_other()
  end

  defp validate_different_location(changeset) do
    changeset
    |> fetch_field!(:different_location)
    |> case do
      true ->
        changeset
        |> validate_required([:location])
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

  defp validate_location_other(changeset) do
    changeset
    |> fetch_field!(:location)
    |> case do
      :other ->
        validate_required(changeset, [:location_details])

      _else ->
        changeset
    end
  end
end
