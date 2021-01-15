defmodule Hygeia.TenantContext.Tenant.Smtp.DKIM do
  @moduledoc """
  Model for DKIM Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          signing_domain_identifier: String.t() | nil,
          domain: String.t() | nil,
          private_key: String.t() | nil
        }

  @type t :: %__MODULE__{
          signing_domain_identifier: String.t(),
          domain: String.t(),
          private_key: String.t()
        }

  embedded_schema do
    field :signing_domain_identifier, :string
    field :domain, :string
    field :private_key, :string
  end

  @doc false
  @spec changeset(
          dkim :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(dkim, attrs) do
    dkim
    |> cast(attrs, [:signing_domain_identifier, :domain, :private_key])
    |> validate_required([:signing_domain_identifier, :domain, :private_key])
    |> validate_hostname(:domain)
    |> validate_dkim_certificate(:private_key)
  end

  @spec to_gen_smtp_opts(dkim :: t) :: Keyword.t()
  def to_gen_smtp_opts(%__MODULE__{
        private_key: private_key,
        signing_domain_identifier: signing_domain_identifier,
        domain: domain
      }) do
    [
      s: signing_domain_identifier,
      d: domain,
      private_key:
        {:pem_plain,
         private_key
         |> dkim_certificate_path()
         |> File.read!()}
    ]
  end
end
