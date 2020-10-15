defmodule Hygeia.CaseContext.ContactMethod do
  @moduledoc """
  Model for Contact Method Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum Type, :contact_method_type, ["mobile", "landline", "email", "other"]

  @type empty :: %__MODULE__{
          type: String.t() | nil,
          comment: String.t() | nil,
          value: String.t() | nil
        }

  @type t :: %__MODULE__{
          type: String.t(),
          comment: String.t() | nil,
          value: String.t()
        }

  embedded_schema do
    field :type, Type
    field :comment, :string
    field :value, :string
  end

  @doc false
  @spec changeset(contact_method :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(contact_method, attrs) do
    contact_method
    |> cast(attrs, [:type, :comment, :value])
    |> validate_required([:type, :value])
  end
end
