defmodule Hygeia.TenantContext.Tenant.SedexExportConfiguration do
  @moduledoc """
  Model for Sedex Export Configuration Schema
  """

  use Hygeia, :model

  alias Hygeia.EctoType.PEMEntry

  @type empty :: %__MODULE__{
          recipient_id: String.t() | nil,
          recipient_public_key: :public_key.public_key() | nil,
          schedule: Crontab.CronExpression.t() | nil
        }

  @type t :: %__MODULE__{
          recipient_id: String.t(),
          recipient_public_key: :public_key.public_key(),
          schedule: Crontab.CronExpression.t()
        }

  embedded_schema do
    field :recipient_id, :string
    field :recipient_public_key, PEMEntry
    field :schedule, Crontab.CronExpression.Ecto.Type
  end

  @doc false
  @spec changeset(
          sedex_export :: t | empty,
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Changeset.t()
  def changeset(sedex_export, attrs) do
    sedex_export
    |> cast(attrs, [:recipient_id, :recipient_public_key, :schedule])
    |> validate_required([:recipient_id, :recipient_public_key, :schedule])
    |> validate_format(:recipient_id, ~R/T?[1-9]-[0-9A-Z]+-[0-9]+|T?0-sedex-0/)
  end
end
