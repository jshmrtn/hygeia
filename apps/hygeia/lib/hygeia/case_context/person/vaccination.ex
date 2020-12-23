defmodule Hygeia.CaseContext.Person.Vaccination do
  @moduledoc """
  Model for Vaccination Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          done: boolean() | nil,
          name: String.t() | nil,
          jab_dates: [Date.t()] | nil
        }

  @type t :: empty

  embedded_schema do
    field :done, :boolean
    field :name, :string
    field :jab_dates, {:array, :date}
  end

  @doc false
  @spec changeset(vaccination :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(vaccination, attrs) do
    vaccination
    |> cast(attrs, [:uuid, :done, :name, :jab_dates])
    |> fill_uuid
  end
end
