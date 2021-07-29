defmodule Hygeia.AutoTracingContext.Transmission do
  @moduledoc """
  Transmission Model
  """
  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  @type t :: %__MODULE__{
          date: Date.t() | nil,
          propagator_known: boolean | nil,
          propagator_first_name: String.t() | nil,
          propagator_last_name: String.t() | nil,
          propagator_address: Address.t() | nil,
          infection_place: InfectionPlace.t() | nil
        }

  @type empty :: %__MODULE__{
          date: Date.t() | nil,
          propagator_known: boolean | nil,
          propagator_first_name: String.t() | nil,
          propagator_last_name: String.t() | nil,
          propagator_address: Address.t() | nil,
          infection_place: InfectionPlace.t() | nil
        }

  embedded_schema do
    field :date, :date
    field :propagator_known, :boolean
    field :propagator_first_name, :string
    field :propagator_last_name, :string

    embeds_one :propagator_address, Address
    embeds_one :infection_place, InfectionPlace
  end

  @spec changeset(transmission :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(transmission, attrs) do
    transmission
    |> cast(attrs, [
      :date,
      :propagator_known,
      :propagator_first_name,
      :propagator_last_name,
      :propagator_case_uuid
    ])
    |> validate_required([])
    |> cast_embed(:infection_place)
    |> cast_embed(:propagator_address)
  end
end
