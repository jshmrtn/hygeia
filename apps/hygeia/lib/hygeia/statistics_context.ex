defmodule Hygeia.StatisticsContext do
  @moduledoc """
  The StatisticsContext context.
  """

  use Hygeia, :context

  alias Hygeia.StatisticsContext.ActiveComplexityCasesPerDay
  alias Hygeia.StatisticsContext.ActiveHospitalizationCasesPerDay
  alias Hygeia.StatisticsContext.ActiveInfectionPlaceCasesPerDay
  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay
  alias Hygeia.StatisticsContext.ActiveQuarantineCasesPerDay
  alias Hygeia.StatisticsContext.CumulativeIndexCaseEndReasons
  alias Hygeia.StatisticsContext.CumulativePossibleIndexCaseEndReasons
  alias Hygeia.StatisticsContext.NewCasesPerDay
  alias Hygeia.StatisticsContext.TransmissionCountryCasesPerDay
  alias Hygeia.TenantContext.Tenant

  @doc """
  Returns the list of active_isolation_cases_per_day.

  ## Examples

      iex> list_active_isolation_cases_per_day()
      [%ActiveIsolationCasesPerDay{}, ...]

  """
  @spec list_active_isolation_cases_per_day :: [ActiveIsolationCasesPerDay.t()]
  def list_active_isolation_cases_per_day,
    do:
      Repo.all(
        from(cases_per_day in ActiveIsolationCasesPerDay,
          order_by: cases_per_day.date
        )
      )

  @spec list_active_isolation_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveIsolationCasesPerDay.t()
        ]
  def list_active_isolation_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in ActiveIsolationCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: cases_per_day.date
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
              fragment("? BETWEEN ?::date AND ?::date", cases_per_day.date, ^from, ^to),
          order_by: cases_per_day.date
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
    do:
      Repo.all(
        from(cumulative_index_case_end_reasons in CumulativeIndexCaseEndReasons,
          order_by: cumulative_index_case_end_reasons.date
        )
      )

  @spec list_cumulative_index_case_end_reasons(tenant :: Tenant.t()) :: [
          CumulativeIndexCaseEndReasons.t()
        ]
  def list_cumulative_index_case_end_reasons(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cumulative_index_case_end_reasons in CumulativeIndexCaseEndReasons,
          where: cumulative_index_case_end_reasons.tenant_uuid == ^tenant_uuid,
          order_by: cumulative_index_case_end_reasons.date
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
                ),
            order_by: cumulative_index_case_end_reasons.date
          )
        )

  @doc """
  Returns the list of active_quarantine_cases_per_day.

  ## Examples

      iex> list_active_quarantine_cases_per_day()
      [%ActiveQuarantineCasesPerDay{}, ...]

  """
  @spec list_active_quarantine_cases_per_day :: [ActiveQuarantineCasesPerDay.t()]
  def list_active_quarantine_cases_per_day,
    do:
      Repo.all(
        from(cases_per_day in ActiveQuarantineCasesPerDay,
          order_by: cases_per_day.date
        )
      )

  @spec list_active_quarantine_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveQuarantineCasesPerDay.t()
        ]
  def list_active_quarantine_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in ActiveQuarantineCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: cases_per_day.date
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
                ),
            order_by: cases_per_day.date
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
    do:
      Repo.all(
        from(cases_per_day in CumulativePossibleIndexCaseEndReasons,
          order_by: cases_per_day.date
        )
      )

  @spec list_cumulative_possible_index_case_end_reasons(tenant :: Tenant.t()) :: [
          CumulativePossibleIndexCaseEndReasons.t()
        ]
  def list_cumulative_possible_index_case_end_reasons(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in CumulativePossibleIndexCaseEndReasons,
          where: cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: cases_per_day.date
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
                ),
            order_by: cases_per_day.date
          )
        )

  @doc """
  Returns the list of new_cases_per_day.

  ## Examples

      iex> list_new_cases_per_day()
      [%NewCasesPerDay{}, ...]

  """
  @spec list_new_cases_per_day :: [NewCasesPerDay.t()]
  def list_new_cases_per_day,
    do:
      Repo.all(
        from(cases_per_day in NewCasesPerDay,
          order_by: cases_per_day.date
        )
      )

  @spec list_new_cases_per_day(tenant :: Tenant.t()) :: [
          NewCasesPerDay.t()
        ]
  def list_new_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in NewCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: cases_per_day.date
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
                ),
            order_by: cases_per_day.date
          )
        )

  @doc """
  Returns the list of active_hospitalization_cases_per_day.

  ## Examples

      iex> list_active_hospitalization_cases_per_day()
      [%ActiveHospitalizationCasesPerDay{}, ...]

  """
  @spec list_active_hospitalization_cases_per_day :: [ActiveHospitalizationCasesPerDay.t()]
  def list_active_hospitalization_cases_per_day,
    do:
      Repo.all(
        from(cases_per_day in ActiveHospitalizationCasesPerDay,
          order_by: cases_per_day.date
        )
      )

  @spec list_active_hospitalization_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveHospitalizationCasesPerDay.t()
        ]
  def list_active_hospitalization_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(cases_per_day in ActiveHospitalizationCasesPerDay,
          where: cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: cases_per_day.date
        )
      )

  @spec list_active_hospitalization_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveHospitalizationCasesPerDay.t()]
  def list_active_hospitalization_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant, from, to),
    do:
      Repo.all(
        from(cases_per_day in ActiveHospitalizationCasesPerDay,
          where:
            cases_per_day.tenant_uuid == ^tenant_uuid and
              fragment("? BETWEEN ?::date AND ?::date", cases_per_day.date, ^from, ^to),
          order_by: cases_per_day.date
        )
      )

  @doc """
  Returns the list of active_complexity_cases_per_day.

  ## Examples

      iex> list_active_complexity_cases_per_day()
      [%ActiveComplexityCasesPerDay{}, ...]

  """
  @spec list_active_complexity_cases_per_day :: [ActiveComplexityCasesPerDay.t()]
  def list_active_complexity_cases_per_day,
    do:
      Repo.all(
        from(active_complexity_cases_per_day in ActiveComplexityCasesPerDay,
          order_by: active_complexity_cases_per_day.date
        )
      )

  @spec list_active_complexity_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveComplexityCasesPerDay.t()
        ]
  def list_active_complexity_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(active_complexity_cases_per_day in ActiveComplexityCasesPerDay,
          where: active_complexity_cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: active_complexity_cases_per_day.date
        )
      )

  @spec list_active_complexity_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveComplexityCasesPerDay.t()]
  def list_active_complexity_cases_per_day(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(active_complexity_cases_per_day in ActiveComplexityCasesPerDay,
            where:
              active_complexity_cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  active_complexity_cases_per_day.date,
                  ^from,
                  ^to
                ),
            order_by: active_complexity_cases_per_day.date
          )
        )

  @doc """
  Returns the list of active_infection_place_cases_per_day.

  ## Examples

      iex> list_active_infection_place_cases_per_day()
      [%ActiveInfectionPlaceCasesPerDay{}, ...]

  """
  @spec list_active_infection_place_cases_per_day :: [ActiveInfectionPlaceCasesPerDay.t()]
  def list_active_infection_place_cases_per_day,
    do:
      Repo.all(
        from(active_infection_place_cases_per_day in ActiveInfectionPlaceCasesPerDay,
          order_by: active_infection_place_cases_per_day.date
        )
      )

  @spec list_active_infection_place_cases_per_day(tenant :: Tenant.t()) :: [
          ActiveInfectionPlaceCasesPerDay.t()
        ]
  def list_active_infection_place_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(active_infection_place_cases_per_day in ActiveInfectionPlaceCasesPerDay,
          where: active_infection_place_cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: active_infection_place_cases_per_day.date
        )
      )

  @spec list_active_infection_place_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveInfectionPlaceCasesPerDay.t()]
  def list_active_infection_place_cases_per_day(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(active_infection_place_cases_per_day in ActiveInfectionPlaceCasesPerDay,
            where:
              active_infection_place_cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  active_infection_place_cases_per_day.date,
                  ^from,
                  ^to
                ),
            order_by: active_infection_place_cases_per_day.date
          )
        )

  @doc """
  Returns the list of transmission_country_cases_per_day.

  ## Examples

      iex> list_transmission_country_cases_per_day()
      [%TransmissionCountryCasesPerDay{}, ...]

  """
  @spec list_transmission_country_cases_per_day :: [TransmissionCountryCasesPerDay.t()]
  def list_transmission_country_cases_per_day,
    do:
      Repo.all(
        from(transmission_country_cases_per_day in TransmissionCountryCasesPerDay,
          order_by: transmission_country_cases_per_day.date
        )
      )

  @spec list_transmission_country_cases_per_day(tenant :: Tenant.t()) :: [
          TransmissionCountryCasesPerDay.t()
        ]
  def list_transmission_country_cases_per_day(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(transmission_country_cases_per_day in TransmissionCountryCasesPerDay,
          where: transmission_country_cases_per_day.tenant_uuid == ^tenant_uuid,
          order_by: transmission_country_cases_per_day.date
        )
      )

  @spec list_transmission_country_cases_per_day(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [TransmissionCountryCasesPerDay.t()]
  def list_transmission_country_cases_per_day(
        %Tenant{uuid: tenant_uuid} = _tenant,
        from,
        to
      ),
      do:
        Repo.all(
          from(transmission_country_cases_per_day in TransmissionCountryCasesPerDay,
            where:
              transmission_country_cases_per_day.tenant_uuid == ^tenant_uuid and
                fragment(
                  "? BETWEEN ?::date AND ?::date",
                  transmission_country_cases_per_day.date,
                  ^from,
                  ^to
                ),
            order_by: transmission_country_cases_per_day.date
          )
        )
end
