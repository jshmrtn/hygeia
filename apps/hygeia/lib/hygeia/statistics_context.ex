defmodule Hygeia.StatisticsContext do
  @moduledoc """
  The StatisticsContext context.
  """

  use Hygeia, :context

  import HygeiaGettext

  alias Hygeia.CaseContext.Case
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.StatisticsContext.ActiveCasesPerDayAndOrganisation
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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [ActiveIsolationCasesPerDay.t()]
  def list_active_isolation_cases_per_day(tenant, from, to, include_zero_values \\ true),
    do: Repo.all(list_active_isolation_cases_per_day_query(tenant, from, to, include_zero_values))

  defp list_active_isolation_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ),
       do:
         from(cases_per_day in ActiveIsolationCasesPerDay,
           where:
             cases_per_day.tenant_uuid == ^tenant_uuid and
               fragment("? BETWEEN ?::date AND ?::date", cases_per_day.date, ^from, ^to) and
               (^include_zero_values or cases_per_day.count > 0),
           order_by: cases_per_day.date
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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [CumulativeIndexCaseEndReasons.t()]
  def list_cumulative_index_case_end_reasons(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_cumulative_index_case_end_reasons_query(tenant, from, to, include_zero_values)
        )

  defp list_cumulative_index_case_end_reasons_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(cumulative_index_case_end_reasons in CumulativeIndexCaseEndReasons,
      where:
        cumulative_index_case_end_reasons.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            cumulative_index_case_end_reasons.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or cumulative_index_case_end_reasons.count > 0),
      order_by: cumulative_index_case_end_reasons.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [ActiveQuarantineCasesPerDay.t()]
  def list_active_quarantine_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_active_quarantine_cases_per_day_query(tenant, from, to, include_zero_values)
        )

  defp list_active_quarantine_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(cases_per_day in ActiveQuarantineCasesPerDay,
      where:
        cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or cases_per_day.count > 0),
      order_by: cases_per_day.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [CumulativePossibleIndexCaseEndReasons.t()]
  def list_cumulative_possible_index_case_end_reasons(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_cumulative_possible_index_case_end_reasons_query(
            tenant,
            from,
            to,
            include_zero_values
          )
        )

  defp list_cumulative_possible_index_case_end_reasons_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(cases_per_day in CumulativePossibleIndexCaseEndReasons,
      where:
        cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or cases_per_day.count > 0),
      order_by: cases_per_day.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [NewCasesPerDay.t()]
  def list_new_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do: Repo.all(list_new_cases_per_day_query(tenant, from, to, include_zero_values))

  defp list_new_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(cases_per_day in NewCasesPerDay,
      where:
        cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or cases_per_day.count > 0),
      order_by: cases_per_day.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [ActiveHospitalizationCasesPerDay.t()]
  def list_active_hospitalization_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_active_hospitalization_cases_per_day_query(tenant, from, to, include_zero_values)
        )

  defp list_active_hospitalization_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ),
       do:
         from(active_hospitalization_cases in ActiveHospitalizationCasesPerDay,
           where:
             active_hospitalization_cases.tenant_uuid == ^tenant_uuid and
               fragment(
                 "? BETWEEN ?::date AND ?::date",
                 active_hospitalization_cases.date,
                 ^from,
                 ^to
               ) and
               (^include_zero_values or active_hospitalization_cases.count > 0),
           order_by: active_hospitalization_cases.date
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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [ActiveComplexityCasesPerDay.t()]
  def list_active_complexity_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_active_complexity_cases_per_day_query(tenant, from, to, include_zero_values)
        )

  defp list_active_complexity_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(active_complexity_cases_per_day in ActiveComplexityCasesPerDay,
      where:
        active_complexity_cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            active_complexity_cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or active_complexity_cases_per_day.count > 0),
      order_by: active_complexity_cases_per_day.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [ActiveInfectionPlaceCasesPerDay.t()]
  def list_active_infection_place_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_active_infection_place_cases_per_day_query(tenant, from, to, include_zero_values)
        )

  defp list_active_infection_place_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(active_infection_place_cases_per_day in ActiveInfectionPlaceCasesPerDay,
      where:
        active_infection_place_cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            active_infection_place_cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or active_infection_place_cases_per_day.count > 0),
      order_by: active_infection_place_cases_per_day.date
    )
  end

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
          to :: Date.t(),
          include_zero_values :: boolean()
        ) :: [TransmissionCountryCasesPerDay.t()]
  def list_transmission_country_cases_per_day(
        tenant,
        from,
        to,
        include_zero_values \\ true
      ),
      do:
        Repo.all(
          list_transmission_country_cases_per_day_query(tenant, from, to, include_zero_values)
        )

  defp list_transmission_country_cases_per_day_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to,
         include_zero_values \\ true
       ) do
    from(transmission_country_cases_per_day in TransmissionCountryCasesPerDay,
      where:
        transmission_country_cases_per_day.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            transmission_country_cases_per_day.date,
            ^from,
            ^to
          ) and
          (^include_zero_values or transmission_country_cases_per_day.count > 0),
      order_by: transmission_country_cases_per_day.date
    )
  end

  @spec export(
          type :: :active_isolation_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_isolation_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(cases_per_day in list_active_isolation_cases_per_day_query(tenant, from, to),
          select: [cases_per_day.date, cases_per_day.count]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :cumulative_index_case_end_reasons,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:cumulative_index_case_end_reasons, tenant, from, to) do
    [[gettext("Date"), gettext("End Reason"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_cumulative_index_case_end_reasons_query(tenant, from, to),
          select: [
            cases_per_day.date,
            cases_per_day.end_reason,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :active_quarantine_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_quarantine_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Type"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(cases_per_day in list_active_quarantine_cases_per_day_query(tenant, from, to),
          select: [
            cases_per_day.date,
            cases_per_day.type,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :cumulative_possible_index_case_end_reasons,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:cumulative_possible_index_case_end_reasons, tenant, from, to) do
    [[gettext("Date"), gettext("Type"), gettext("End Reason"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_cumulative_possible_index_case_end_reasons_query(tenant, from, to),
          select: [
            cases_per_day.date,
            cases_per_day.type,
            cases_per_day.end_reason,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :new_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:new_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Type"), gettext("Sub-Type"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(cases_per_day in list_new_cases_per_day_query(tenant, from, to),
          select: [
            cases_per_day.date,
            cases_per_day.type,
            cases_per_day.sub_type,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :active_hospitalization_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_hospitalization_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_active_hospitalization_cases_per_day_query(
            tenant,
            from,
            to
          ),
          select: [
            cases_per_day.date,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :active_complexity_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_complexity_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Complexity"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_active_complexity_cases_per_day_query(
            tenant,
            from,
            to
          ),
          select: [
            cases_per_day.date,
            cases_per_day.case_complexity,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :active_infection_place_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_infection_place_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Type"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_active_infection_place_cases_per_day_query(
            tenant,
            from,
            to
          ),
          select: [
            cases_per_day.date,
            cases_per_day.infection_place_type,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  @spec export(
          type :: :transmission_country_cases_per_day,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:transmission_country_cases_per_day, tenant, from, to) do
    [[gettext("Date"), gettext("Country"), gettext("Count")]]
    |> Stream.concat(
      Repo.stream(
        from(
          cases_per_day in list_transmission_country_cases_per_day_query(
            tenant,
            from,
            to
          ),
          select: [
            cases_per_day.date,
            cases_per_day.country,
            cases_per_day.count
          ]
        )
      )
    )
    |> CSV.encode()
  end

  # Export for only "from" day !
  @spec export(
          type :: :active_cases_per_day_and_organisation,
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: Enumerable.t()
  def export(:active_cases_per_day_and_organisation, tenant, from, _to) do
    [[gettext("Organisation"), gettext("Division"), gettext("Type"), gettext("Count")]]
    |> Stream.concat(
      Stream.map(
        Repo.stream(
          from(
            cases_per_day in list_active_cases_per_day_organisation_division_kind_query(
              tenant,
              from
            )
          )
        ),
        fn [organisation, division, affiliation_kind, count] ->
          [organisation, division, Kind.translate_affiliation_kind(affiliation_kind), count]
        end
      )
    )
    |> CSV.encode()
  end

  defp list_active_cases_per_day_organisation_division_kind_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         date
       ),
       do:
         from(
           case in Case,
           join: phase in fragment("UNNEST(?)", case.phases),
           join: person in assoc(case, :person),
           join: affiliation in assoc(person, :affiliations),
           join: organisation in assoc(affiliation, :organisation),
           left_join: division in assoc(affiliation, :division),
           where:
             case.tenant_uuid == ^tenant_uuid and
               fragment("?->'details'->>'__type__'", phase) == "index" and
               coalesce(
                 fragment("(?->>'start')::date", phase),
                 fragment("?::date", case.inserted_at)
               ) <= ^date and
               coalesce(fragment("(?->>'end')::date", phase), fragment("CURRENT_DATE")) >= ^date,
           group_by: [
             organisation.uuid,
             division.uuid,
             affiliation.kind
           ],
           order_by: [
             organisation.name,
             division.title,
             desc: count(person.uuid)
           ],
           select: [
             organisation.name,
             division.title,
             affiliation.kind,
             count(person.uuid)
           ]
         )

  @doc """
  Returns the list of active cases per day and organisation.

  ## Examples

      iex> list_active_cases_per_day_and_organisation()
      [%ActiveCasesPerDayAndOrganisation{}, ...]

  """
  @spec list_active_cases_per_day_and_organisation :: [ActiveCasesPerDayAndOrganisation.t()]
  def list_active_cases_per_day_and_organisation,
    do:
      Repo.all(
        from(active_cases_per_day_and_organisation in ActiveCasesPerDayAndOrganisation,
          order_by: active_cases_per_day_and_organisation.date
        )
      )

  @spec list_active_cases_per_day_and_organisation(tenant :: Tenant.t()) :: [
          ActiveCasesPerDayAndOrganisation.t()
        ]
  def list_active_cases_per_day_and_organisation(%Tenant{uuid: tenant_uuid} = _tenant),
    do:
      Repo.all(
        from(active_cases_per_day_and_organisation in ActiveCasesPerDayAndOrganisation,
          where: active_cases_per_day_and_organisation.tenant_uuid == ^tenant_uuid,
          order_by: active_cases_per_day_and_organisation.date
        )
      )

  @spec list_active_cases_per_day_and_organisation(
          tenant :: Tenant.t(),
          from :: Date.t(),
          to :: Date.t()
        ) :: [ActiveCasesPerDayAndOrganisation.t()]
  def list_active_cases_per_day_and_organisation(
        tenant,
        from,
        to
      ),
      do: Repo.all(list_active_cases_per_day_and_organisation_query(tenant, from, to))

  defp list_active_cases_per_day_and_organisation_query(
         %Tenant{uuid: tenant_uuid} = _tenant,
         from,
         to
       ) do
    from(active_cases_per_day_and_organisation in ActiveCasesPerDayAndOrganisation,
      where:
        active_cases_per_day_and_organisation.tenant_uuid == ^tenant_uuid and
          fragment(
            "? BETWEEN ?::date AND ?::date",
            active_cases_per_day_and_organisation.date,
            ^from,
            ^to
          ),
      order_by: active_cases_per_day_and_organisation.date,
      preload: [:organisation]
    )
  end
end
