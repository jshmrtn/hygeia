defmodule Hygeia.StatisticsContext do
  @moduledoc """
  The StatisticsContext context.
  """

  import Ecto.Query, warn: false
  alias Hygeia.Repo

  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay
  alias Hygeia.StatisticsContext.ActiveQuarantineCasesPerDay
  alias Hygeia.StatisticsContext.CumulativeIndexCaseEndReasons
  alias Hygeia.StatisticsContext.CumulativePossibleIndexCaseEndReasons
  alias Hygeia.StatisticsContext.NewCasesPerDay
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

  @doc """
  Returns the list of cumulative_index_case_end_reasons.

  ## Examples

      iex> list_cumulative_index_case_end_reasons()
      [%CumulativeIndexCaseEndReasons{}, ...]

  """
  @spec list_cumulative_index_case_end_reasons :: [CumulativeIndexCaseEndReasons.t()]
  def list_cumulative_index_case_end_reasons,
    do: Repo.all(CumulativeIndexCaseEndReasons)

  @spec list_cumulative_index_case_end_reasons(tenant :: Tenant.t()) :: [
          CumulativeIndexCaseEndReasons.t()
        ]
  def list_cumulative_index_case_end_reasons(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cumulative_index_case_end_reasons in CumulativeIndexCaseEndReasons,
          where: cumulative_index_case_end_reasons.tenant_uuid == ^tenant_uuid
        )
      )

  @spec list_cumulative_index_case_end_reasons(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [CumulativeIndexCaseEndReasons.t()]
  def list_cumulative_index_case_end_reasons(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(cumulative_index_case_end_reasons in CumulativeIndexCaseEndReasons,
            where:
              cumulative_index_case_end_reasons.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  cumulative_index_case_end_reasons.date,
                  ^from,
                  ^to
                )
          )
        )

  @doc """
  Returns the list of active_quarantine_cases_per_day.

  ## Examples

      iex> list_active_quarantine_cases_per_day()
      [%ActiveQuarantineCasesPerDay{}, ...]

  """
  @spec list_active_quarantine_cases_per_day :: [ActiveQuarantineCasesPerDay.t()]
  def list_active_quarantine_cases_per_day, do: Repo.all(ActiveQuarantineCasesPerDay)

  @spec list_active_quarantine_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveQuarantineCasesPerDay.t()
        ]
  def list_active_quarantine_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in ActiveQuarantineCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid
        )
      )

  @spec list_active_quarantine_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveQuarantineCasesPerDay.t()]
  def list_active_quarantine_cases_per_day(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(cases_per_day in ActiveQuarantineCasesPerDay,
            where:
              cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  cases_per_day.date,
                  ^from,
                  ^to
                )
          )
        )

  @doc """
  Returns the list of cumulative_possible_index_case_end_reasons.

  ## Examples

      iex> list_cumulative_possible_index_case_end_reasons()
      [%CumulativePossibleIndexCaseEndReasons{}, ...]

  """
  @spec list_cumulative_possible_index_case_end_reasons :: [
          CumulativePossibleIndexCaseEndReasons.t()
        ]
  def list_cumulative_possible_index_case_end_reasons,
    do: Repo.all(CumulativePossibleIndexCaseEndReasons)

  @spec list_cumulative_possible_index_case_end_reasons(tenant :: Tenant.t()) :: [
          CumulativePossibleIndexCaseEndReasons.t()
        ]
  def list_cumulative_possible_index_case_end_reasons(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in CumulativePossibleIndexCaseEndReasons,
          where: cases_per_day.tenant_uuid == ^tenant_uuid
        )
      )

  @spec list_cumulative_possible_index_case_end_reasons(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [CumulativePossibleIndexCaseEndReasons.t()]
  def list_cumulative_possible_index_case_end_reasons(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(cases_per_day in CumulativePossibleIndexCaseEndReasons,
            where:
              cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  cases_per_day.date,
                  ^from,
                  ^to
                )
          )
        )

  @doc """
  Returns the list of new_cases_per_day.

  ## Examples

      iex> list_new_cases_per_day()
      [%NewCasesPerDay{}, ...]

  """
  @spec list_new_cases_per_day :: [NewCasesPerDay.t()]
  def list_new_cases_per_day, do: Repo.all(NewCasesPerDay)

  @spec list_new_cases_per_day(tenant :: Tenant.t()) :: [
          NewCasesPerDay.t()
        ]
  def list_new_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in NewCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid
        )
      )

  @spec list_new_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [NewCasesPerDay.t()]
  def list_new_cases_per_day(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(cases_per_day in NewCasesPerDay,
            where:
              cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  cases_per_day.date,
                  ^from,
                  ^to
                )
          )
        )
end
