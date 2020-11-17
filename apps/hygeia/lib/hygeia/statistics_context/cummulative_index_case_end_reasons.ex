defmodule Hygeia.StatisticsContext.CumulativeIndexCaseEndReasons do
  @moduledoc """
  Model for Tenants
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Phase.Index.EndReason
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          end_reason: EndReason.t(),
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_cumulative_index_case_end_reasons" do
    field :count, :integer
    field :date, :date
    field :end_reason, EndReason

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
