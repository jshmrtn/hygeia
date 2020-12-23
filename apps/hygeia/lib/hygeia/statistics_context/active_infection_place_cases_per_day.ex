defmodule Hygeia.StatisticsContext.ActiveInfectionPlaceCasesPerDay do
  @moduledoc """
  Model for Active Infection Place Cases Per Day
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Transmission.InfectionPlace.Type
  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          infection_place_type: Type.t() | nil,
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_active_infection_place_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :infection_place_type, Type

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
