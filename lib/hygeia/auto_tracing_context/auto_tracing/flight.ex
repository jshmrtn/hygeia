defmodule Hygeia.AutoTracingContext.AutoTracing.Flight do
  @moduledoc "Module responsible for tracking flight information."

  use Hygeia, :model

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          flight_date: Date.t(),
          departure_place: String.t() | nil,
          arrival_place: String.t() | nil,
          flight_number: String.t() | nil,
          seat_number: String.t() | nil,
          wore_mask: boolean() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          flight_date: Date.t(),
          departure_place: String.t() | nil,
          arrival_place: String.t() | nil,
          flight_number: String.t() | nil,
          seat_number: String.t() | nil,
          wore_mask: boolean() | nil
        }

  embedded_schema do
    field :flight_date, :date
    field :departure_place, :string
    field :arrival_place, :string
    field :flight_number, :string
    field :seat_number, :string
    field :wore_mask, :boolean
  end

  @spec changeset(schema :: t() | empty() | Changeset.t(t() | empty()), attrs :: map()) ::
          Ecto.Changeset.t(t())
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :uuid,
      :departure_place,
      :arrival_place,
      :flight_date,
      :flight_number,
      :seat_number,
      :wore_mask
    ])
    |> validate_required([
      :departure_place,
      :arrival_place,
      :flight_date,
      :flight_number,
      :seat_number,
      :wore_mask
    ])
  end
end
