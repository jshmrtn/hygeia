defmodule Hygeia.TenantContext.Tenant.TemplateParameters do
  @moduledoc """
  Model for Template Parameters Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          sms_signature: String.t() | nil,
          email_signature: String.t() | nil
        }

  @type t :: %__MODULE__{
          sms_signature: String.t() | nil,
          email_signature: String.t() | nil
        }

  embedded_schema do
    field :sms_signature, :string
    field :email_signature, :string
  end

  @doc false
  @spec changeset(
          template_parameters :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(template_parameters, attrs) do
    template_parameters
    |> cast(attrs, [:sms_signature, :email_signature])
    |> validate_required([])
  end
end
