defmodule Hygeia.StatisticsContext.HospitalAdmissionCasesPerDay do
  @moduledoc """
  Model for Active Hospitalization Cases Per Day
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
  schema "statistics_hospital_admission_cases_per_day" do
    field :count, :integer
    field :date, :date

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
