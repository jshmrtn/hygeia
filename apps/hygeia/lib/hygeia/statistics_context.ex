defmodule Hygeia.StatisticsContext do
  @moduledoc """
  The StatisticsContext context.
  """

  import Ecto.Query, warn: false
  alias Hygeia.Repo

  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay
  alias Hygeia.TenantContext.Tenant

  @doc """
  Returns the list of active_isolation_cases_per_day.

  ## Examples

      iex> list_active_isolation_cases_per_day()
      [%ActiveIsolationCasesPerDay{}, ...]

  """
  @spec list_active_isolation_cases_per_day :: [ActiveIsolationCasesPerDay.t()]
  def list_active_isolation_cases_per_day, do: Repo.all(ActiveIsolationCasesPerDay)

  @spec list_active_isolation_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveIsolationCasesPerDay.t()
        ]
  def list_active_isolation_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in ActiveIsolationCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid
        )
      )

  @spec list_active_isolation_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveIsolationCasesPerDay.t()]
  def list_active_isolation_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant, from, to),
    do:
      Repo.all(
        from(cases_per_day in ActiveIsolationCasesPerDay,
          where:
            cases_per_day.tenant_uuid == ^tenant_uuid and
              fragment("? BETWEEN ?::date AND ?::date", cases_per_day.date, ^from, ^to)
        )
      )
end
