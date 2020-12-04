defmodule Hygeia.StatisticsContext.TransmissionCountryCasesPerDay do
  @moduledoc """
  Model for Transmission Country Cases Per Day
  """

  use Hygeia, :model

  alias Hygeia.TenantContext.Tenant

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          date: Date.t(),
          country: String.t() | nil,
          tenant_uuid: String.t(),
          tenant: Ecto.Schema.belongs_to(Tenant.t())
        }

  @primary_key false
  schema "statistics_transmission_country_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :country, :string

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
