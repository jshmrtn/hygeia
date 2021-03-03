defmodule Hygeia.StatisticsContext.ActiveCasesPerDayAndOrganisation do
  @moduledoc """
  Model for  Active Isolation Cases Per Day And Organisation
  """

  use Hygeia, :model

  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t()),
          organisation_uuid: String.t(),
          organisation: Ecto.Schema.belongs_to(Organisation.t())
        }

  @primary_key false
  schema "statistics_active_cases_per_day_and_organisation" do
    field :count, :integer
    field :date, :date

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    belongs_to :organisation, Organisation, references: :uuid, foreign_key: :organisation_uuid
  end
end
