defmodule Hygeia.CaseContext.Hospitalization do
  @moduledoc """
  Model for Hospitalization Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil
        }

  @type t :: %__MODULE__{
          start: Date.t() | nil,
          end: Date.t() | nil
        }

  embedded_schema do
    field :start, :date
    field :end, :date
    # TODO: Add Organisation Link
  end

  @doc false
  @spec changeset(hospitalization :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(hospitalization, attrs) do
    hospitalization
    |> cast(attrs, [:start, :end])
    |> validate_required([])
  end
end
