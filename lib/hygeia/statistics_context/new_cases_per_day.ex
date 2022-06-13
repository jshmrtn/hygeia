defmodule Hygeia.StatisticsContext.NewCasesPerDay do
  @moduledoc """
  Model for New cases per Day
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type, as: PossibleIndexType
  alias Hygeia.TenantContext.Tenant

  defenum Type, :case_phase_type, [
    "index",
    "possible_index"
  ]

  @type t ::
          %__MODULE__{
            count: non_neg_integer(),
            date: Date.t(),
            type: :index,
            sub_type: nil,
            tenant_uuid: Ecto.UUID.t(),
            tenant: Ecto.Schema.belongs_to(Tenant.t())
          }
          | %__MODULE__{
              count: non_neg_integer(),
              date: Date.t(),
              type: :possible_index,
              sub_type: PossibleIndexType.t(),
              tenant_uuid: Ecto.UUID.t(),
              tenant: Ecto.Schema.belongs_to(Tenant.t())
            }

  @primary_key false
  schema "statistics_new_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :type, Type
    field :sub_type, PossibleIndexType

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
