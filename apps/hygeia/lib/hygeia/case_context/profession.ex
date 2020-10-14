defmodule Hygeia.CaseContext.Profession do
  @moduledoc """
  Model for Person / Profession Schema
  """

  use Hygeia, :model

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "professions" do
    field :name, :string

    timestamps()
  end

  @doc false
  @spec changeset(profession :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(profession, attrs) do
    profession
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
