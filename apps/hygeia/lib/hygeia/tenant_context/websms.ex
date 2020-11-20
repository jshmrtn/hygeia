defmodule Hygeia.TenantContext.Websms do
  @moduledoc """
  Model for Smtp Outgoing Mail Configuration Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          access_token: String.t() | nil
        }

  @type t :: %__MODULE__{
          access_token: String.t()
        }

  embedded_schema do
    field :access_token, :string
  end

  @doc false
  @spec changeset(
          websms :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(websms, attrs) do
    websms
    |> cast(attrs, [:access_token])
    |> validate_required([:access_token])
  end
end
