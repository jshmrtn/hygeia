defmodule Hygeia.TenantContext.Tenant.Smtp do
  @moduledoc """
  Model for Smtp Outgoing Mail Configuration Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          server: String.t() | nil,
          hostname: String.t() | nil,
          port: integer() | nil,
          from_email: String.t() | nil,
          username: String.t() | nil,
          password: String.t() | nil
        }

  @type t :: %__MODULE__{
          server: String.t(),
          hostname: String.t(),
          port: integer(),
          from_email: String.t(),
          username: String.t(),
          password: String.t()
        }

  embedded_schema do
    field :server, :string
    field :hostname, :string
    field :port, :integer
    field :from_email, :string
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
    |> cast(attrs, [:server, :hostname, :port, :from_email, :username, :password])
    |> validate_required([:server, :port, :from_email])
    |> validate_number(:port, greater_than: 0, less_than: 65_536)
    |> validate_hostname_format(:server)
    |> validate_hostname_format(:hostname)
  end

  @spec validate_hostname_format(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  defp validate_hostname_format(changeset, field) do
    validate_format(
      changeset,
      field,
      ~r/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
    )
  end
end
