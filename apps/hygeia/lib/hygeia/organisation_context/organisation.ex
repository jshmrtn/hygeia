defmodule Hygeia.OrganisationContext.Organisation do
  @moduledoc """
  Model for Organisations
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Address
  alias Hygeia.OrganisationContext.Position

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          address: Address.t() | nil,
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          address: Address.t(),
          notes: String.t() | nil,
          positions: Ecto.Schema.has_many(Position.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "organisations" do
    field :name, :string
    field :notes, :string

    embeds_one :address, Address, on_replace: :delete
    has_many :positions, Position, foreign_key: :organisation_uuid

    timestamps()
  end

  @doc false
  @spec changeset(organisation :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :notes])
    |> validate_required([:name])
    |> cast_embed(:address)
  end
end
