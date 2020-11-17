defmodule Hygeia.StatisticsContext.ActiveQuarantineCasesPerDay do
  @moduledoc """
  Model for Active Quarantine Cases Per Day
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          type: Type.t()
        }

  @primary_key false
  schema "statistics_active_quarantine_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :type, Type

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
