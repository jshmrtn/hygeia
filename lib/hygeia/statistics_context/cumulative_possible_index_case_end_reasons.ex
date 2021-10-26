defmodule Hygeia.StatisticsContext.CumulativePossibleIndexCaseEndReasons do
  @moduledoc """
  Model for Cumulative Possible Index Case End Reasons
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          end_reason: EndReason.t() | nil,
          type: Type.t(),
          tenant_uuid: Ecto.UUID.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_cumulative_possible_index_case_end_reasons" do
    field :count, :integer
    field :date, :date
    field :type, Type
    field :end_reason, EndReason

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
