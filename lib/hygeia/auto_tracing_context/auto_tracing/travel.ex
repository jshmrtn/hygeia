defmodule Hygeia.AutoTracingContext.AutoTracing.Travel do
  @moduledoc "Module responsible for tracking travel information."

  use Hygeia, :model

  alias Hygeia.EctoType.Country

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          last_departure_date: Date.t(),
          country: Country.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          last_departure_date: Date.t(),
          country: Country.t() | nil
        }

  embedded_schema do
    field :last_departure_date, :date
    field :country, Country
  end

  @spec changeset(
          schema :: t() | empty() | Changeset.t(t() | empty()),
          attrs :: map(),
          opts :: map()
        ) ::
          Ecto.Changeset.t(t())
  def changeset(schema, attrs \\ %{}, opts \\ %{})

  def changeset(schema, attrs, %{require_last_departure_date: true}) do
    schema
    |> changeset(attrs, %{require_last_departure_date: false})
    |> validate_required([:last_departure_date])
  end

  def changeset(schema, attrs, _opts) do
    schema
    |> cast(attrs, [
      :uuid,
      :last_departure_date,
      :country
    ])
    |> validate_required([:country])
    |> validate_past_date(:last_departure_date)
  end
end
