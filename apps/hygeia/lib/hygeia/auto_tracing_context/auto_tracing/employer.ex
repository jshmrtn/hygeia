defmodule Hygeia.AutoTracingContext.AutoTracing.Employer do
  @moduledoc """
  Employer Model
  """
  use Hygeia, :model

  alias Hygeia.CaseContext.Address

  @type t :: %__MODULE__{
          organisation_uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          address: Address.t() | nil
        }

  @type empty :: %__MODULE__{
          organisation_uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          address: Address.t() | nil
        }

  embedded_schema do
    field :organisation_uuid, :binary_id
    field :name, :string

    embeds_one :address, Address, on_replace: :update
  end

  @spec changeset(employer :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(t)
  def changeset(employer, attrs) do
    employer
    |> cast(attrs, [:name, :organisation_uuid])
    |> validate_required([])
    |> cast_embed(:address)
  end
end
