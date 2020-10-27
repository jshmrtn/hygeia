defmodule Hygeia.CaseContext.Sms do
  @moduledoc """
  Model for Sms Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          text: String.t() | nil,
          delivery_receipt_id: String.t() | nil
        }

  @type t :: %__MODULE__{
          text: String.t(),
          delivery_receipt_id: String.t()
        }

  embedded_schema do
    field :text, :string
    field :delivery_receipt_id, :string
  end

  @doc false
  @spec changeset(sms :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(sms, attrs) do
    sms
    |> cast(attrs, [:text, :delivery_receipt_id])
    |> validate_required([:text, :delivery_receipt_id])
  end
end
