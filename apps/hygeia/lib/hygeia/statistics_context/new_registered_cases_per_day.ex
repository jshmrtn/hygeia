defmodule Hygeia.StatisticsContext.NewRegisteredCasesPerDay do
  @moduledoc """
  Model for New Registered Cases per Day
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case.Phase.Type
  alias Hygeia.TenantContext.Tenant

  @type t ::
          %__MODULE__{
            count: non_neg_integer(),
            date: Date.t(),
            type: Type.t(),
            first_contact: boolean,
            tenant_uuid: Ecto.UUID.t(),
            tenant: Ecto.Schema.belongs_to(Tenant.t())
          }

  @primary_key false
  schema "statistics_new_registered_cases_per_day" do
    field :count, :integer
    field :date, :date
    field :type, Type
    field :first_contact, :boolean

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
  end
end
