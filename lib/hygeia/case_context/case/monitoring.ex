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

  @type changeset_options :: %{required(:complete_data_required) => boolean}

  embedded_schema do
    field :first_contact, :date
    field :location, IsolationLocation
    field :location_details, :string
    field :different_location, :boolean, default: false

    embeds_one :address, Address, on_replace: :update
  end

  @doc false
  @spec changeset(
          monitoring :: t | empty,
          attrs :: Hygeia.ecto_changeset_params(),
          opts :: changeset_options
        ) ::
          Changeset.t()
  def changeset(monitoring, attrs \\ %{}, changeset_options) do
    monitoring
    |> cast(attrs, [:first_contact, :location, :location_details, :different_location])
    |> validate_different_location(changeset_options)
    |> validate_location_other(changeset_options)
  end

  defp validate_different_location(
         changeset,
         %{complete_data_required: complete_data_required} = _changeset_options
       ) do
    changeset
    |> fetch_field!(:different_location)
    |> case do
      true ->
        changeset =
          changeset
          |> validate_required([:location])
          |> cast_embed(:address,
            with: &Address.changeset(&1, &2, %{required: complete_data_required}),
            required: true
          )

        if complete_data_required do
          validate_embed_required(changeset, :address, Address)
        else
          changeset
        end

      _else ->
        changeset
        |> put_change(:location, nil)
        |> put_change(:location_details, nil)
        |> put_change(:address, nil)
    end
  end

  defp validate_location_other(
         changeset,
         %{complete_data_required: complete_data_required} = _changeset_options
       ) do
    with :other <- fetch_field!(changeset, :location),
         true <- complete_data_required do
      validate_required(changeset, [:location_details])
    else
      _not_required -> changeset
    end
  end
end
