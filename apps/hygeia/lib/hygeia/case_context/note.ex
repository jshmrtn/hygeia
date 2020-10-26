defmodule Hygeia.CaseContext.Note do
  @moduledoc """
  Model for Note Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          note: String.t() | nil
        }

  @type t :: %__MODULE__{
          note: String.t()
        }

  embedded_schema do
    field :note, :string
  end

  @doc false
  @spec changeset(note :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:note])
    |> validate_required([:note])
  end
end
