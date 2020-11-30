defmodule Hygeia.StatisticsContext.ActiveComplexityCasesPerDay do
  @moduledoc """
  Model for Active Complexity Cases Per Day
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Complexity
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          case_complexity: Complexity.t() | nil,
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_active_complexity_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :case_complexity, Complexity

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
