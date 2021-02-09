defmodule Hygeia.TenantContext.Tenant.TemplateParameters do
  @moduledoc """
  Model for Template Parameters Schema
  """

  use Hygeia, :model

  import Ecto.Changeset

  @type empty :: %__MODULE__{
          message_sender: String.t() | nil
        }

  @type t :: %__MODULE__{
          message_sender: String.t() | nil
        }

  embedded_schema do
    field :message_sender, :string
  end

  @doc false
  @spec changeset(
          template_parameters :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(template_parameters, attrs) do
    template_parameters
    |> cast(attrs, [:message_sender])
    |> validate_required([])
  end
end
