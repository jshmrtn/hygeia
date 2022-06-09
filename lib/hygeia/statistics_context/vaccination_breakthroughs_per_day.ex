defmodule Hygeia.StatisticsContext.VaccinationBreakthroughsPerDay do
  @moduledoc """
  Model for Vaccination breakthroughs per Day
  """

  use Hygeia, :model

  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          tenant_uuid: Ecto.UUID.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_vaccination_breakthroughs_per_day" do
    field :count, :integer
    field :date, :date

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
