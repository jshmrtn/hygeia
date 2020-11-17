defmodule Hygeia.CaseContext.ProtocolEntry.Email do
  @moduledoc """
  Model for Email Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          subject: String.t() | nil,
          body: String.t() | nil
        }

  @type t :: %__MODULE__{
          subject: String.t(),
          body: String.t()
        }

  embedded_schema do
    field :subject, :string
    field :body, :string
  end

  @doc false
  @spec changeset(email :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(email, attrs) do
    email
    |> cast(attrs, [:subject, :body])
    |> validate_required([:subject, :body])
  end
end
