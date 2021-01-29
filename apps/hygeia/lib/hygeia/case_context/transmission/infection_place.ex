defmodule Hygeia.CaseContext.Transmission.InfectionPlace do
  @moduledoc """
  Model for InfectionPlace Schema
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Address

  defenum Type, :infection_place_type, [
    "work_place",
    "army",
    "asyl",
    "choir",
    "club",
    "hh",
    "high_school",
    "childcare",
    "erotica",
    "flight",
    "medical",
    "hotel",
    "child_home",
    "cinema",
    "shop",
    "school",
    "less_300",
    "more_300",
    "public_transp",
    "massage",
    "nursing_home",
    "religion",
    "restaurant",
    "school_camp",
    "indoor_sport",
    "outdoor_sport",
    "gathering",
    "zoo",
    "prison",
    "other"
  ]

  @type empty :: %__MODULE__{
          address: Address.t() | nil,
          known: boolean() | nil,
          activity_mapping_executed: boolean() | nil,
          activity_mapping: String.t() | nil,
          type: Type.t() | nil,
          type_other: String.t() | nil,
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
    field :type, Type
    field :type_other, :string

    embeds_one :address, Address, on_replace: :update
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
      :name,
      :flight_information,
      :type,
      :type_other
    ])
    |> validate_required([])
    |> cast_embed(:address)
    |> validate_type_other()
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
  end
end
