defmodule Hygeia.TenantContext.Tenant.Smtp.Relay do
  @moduledoc """
  Model for Smtp Relay Schema
  """

  use Hygeia, :model

  @type empty :: %__MODULE__{
          server: String.t() | nil,
          hostname: String.t() | nil,
          port: integer() | nil,
          username: String.t() | nil,
          password: String.t() | nil
        }

  @type t :: %__MODULE__{
          server: String.t(),
          hostname: String.t(),
          port: integer(),
          username: String.t(),
          password: String.t()
        }

  embedded_schema do
    field :server, :string
    field :hostname, :string
    field :port, :integer
    field :username, :string
    field :password, :string
  end

  @doc false
  @spec changeset(
          smtp :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(smtp, attrs) do
    smtp
    |> cast(attrs, [:server, :hostname, :port, :username, :password])
    |> validate_required([:server, :port])
    |> validate_number(:port, greater_than: 0, less_than: 65_536)
    |> validate_hostname(:server)
    |> validate_hostname(:hostname)
  end
end
