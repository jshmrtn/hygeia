defmodule Hygeia.AutoTracingContext.AutoTracing.Travel do
  @moduledoc "Module responsible for tracking travel information."

  use Hygeia, :model

  alias Hygeia.EctoType.Country

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          return_date: Date.t(),
          country: Country.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          return_date: Date.t(),
          country: Country.t() | nil
        }

  embedded_schema do
    field :return_date, :date
    field :country, Country
  end

  @spec changeset(schema :: t() | empty() | Changeset.t(t() | empty()), attrs :: map()) ::
          Ecto.Changeset.t(t())
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :uuid,
      :return_date,
      :country
    ])
    |> validate_required([
      :return_date,
      :country
    ])
  end
end
