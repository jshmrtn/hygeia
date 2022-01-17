# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule Hygeia.StatisticsContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex
  alias Hygeia.StatisticsContext
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
  alias Hygeia.StatisticsContext.VaccinationBreakthroughsPerDay

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "active_isolation_cases_per_day" do
    test "lists index case with date" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3,
            quarantine_order: true
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      assert [
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_1},
               %ActiveIsolationCasesPerDay{count: 1, date: ^day_2},
               %ActiveIsolationCasesPerDay{count: 1, date: ^day_3},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_4}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "does not list index case with only inserted_at date" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            }
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      assert [
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_1},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_2},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_3},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_4}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "does not list case without index phase" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :contact_person,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_3
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      assert [
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_1},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_2},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_3},
               %ActiveIsolationCasesPerDay{count: 0, date: ^day_4}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "exports index cases" do
      [day_1, day_2, day_3, day_4] =
        dates = Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      [day_1_iso, day_2_iso, day_3_iso, day_4_iso] = Enum.map(dates, &Date.to_iso8601/1)

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3,
            quarantine_order: true
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      Repo.transaction(fn ->
        assert [
                 ["Date", "Count"],
                 [^day_1_iso, "0"],
                 [^day_2_iso, "1"],
                 [^day_3_iso, "1"],
                 [^day_4_iso, "0"]
               ] =
                 :active_isolation_cases_per_day
                 |> StatisticsContext.export(tenant, day_1, day_4)
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()
      end)
    end
  end

  describe "cumulative_index_case_end_reasons" do
    test "counts cases from the end date" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(
               entries,
               &(match?(%CumulativeIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativeIndexCaseEndReasons{count: 1, end_reason: :healed, date: date}
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does count end_reason nil" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: nil
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(
               entries,
               &(match?(%CumulativeIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativeIndexCaseEndReasons{count: 1, end_reason: nil, date: date}
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does not count possible index" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :contact_person,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_2,
            quarantine_order: true
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(entries, &match?(%CumulativeIndexCaseEndReasons{count: 0}, &1))
    end

    test "exports cumulative index case end reasons" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      Repo.transaction(fn ->
        assert entries =
                 :cumulative_index_case_end_reasons
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 21
      end)
    end
  end

  describe "active_quarantine_cases_per_day" do
    test "lists index case with date" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_3
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      assert entries =
               StatisticsContext.list_active_quarantine_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )

      assert length(entries) == 20

      assert Enum.all?(
               entries,
               &(match?(%ActiveQuarantineCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveQuarantineCasesPerDay{count: 1, type: :travel, date: date}
                     when date in [day_2, day_3, day_4],
                     &1
                   ))
             )
    end

    test "lists index case with only inserted_at date" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        inserted_at: ~U[2020-10-12 11:34:21.423847Z],
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: :asymptomatic
            }
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      assert entries =
               StatisticsContext.list_active_quarantine_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )

      assert length(entries) == 20

      assert Enum.all?(
               entries,
               &(match?(%ActiveQuarantineCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveQuarantineCasesPerDay{count: 1, type: :travel, date: date}
                     when date in [day_2, day_3, day_4],
                     &1
                   ))
             )
    end

    test "does not list case without index phase" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      assert entries =
               StatisticsContext.list_active_quarantine_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )

      assert length(entries) == 20

      assert Enum.all?(entries, &match?(%ActiveQuarantineCasesPerDay{count: 0}, &1))
    end

    test "exports quarantine cases" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_3
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :active_quarantine_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 21
      end)
    end
  end

  describe "cumulative_possible_index_case_end_reasons" do
    test "counts cases from the end date" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) ==
               (length(PossibleIndex.EndReason.__enum_map__()) + 1) *
                 length(PossibleIndex.Type.__enum_map__()) * 3

      assert Enum.all?(
               entries,
               &(match?(%CumulativePossibleIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativePossibleIndexCaseEndReasons{
                       count: 1,
                       end_reason: :asymptomatic,
                       date: date,
                       type: :travel
                     }
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does count end_reason nil" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: nil
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) ==
               (length(PossibleIndex.EndReason.__enum_map__()) + 1) *
                 length(PossibleIndex.Type.__enum_map__()) * 3

      assert Enum.all?(
               entries,
               &(match?(%CumulativePossibleIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativePossibleIndexCaseEndReasons{
                       count: 1,
                       end_reason: nil,
                       type: :travel,
                       date: date
                     }
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does not count possible index" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) ==
               (length(PossibleIndex.EndReason.__enum_map__()) + 1) *
                 length(PossibleIndex.Type.__enum_map__()) * 3

      assert Enum.all?(entries, &match?(%CumulativePossibleIndexCaseEndReasons{count: 0}, &1))
    end

    test "exports cumulative possible index case end reasons" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :travel,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      Repo.transaction(fn ->
        assert entries =
                 :cumulative_possible_index_case_end_reasons
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) ==
                 (length(PossibleIndex.EndReason.__enum_map__()) + 1) *
                   length(PossibleIndex.Type.__enum_map__()) * 4 + 1
      end)
    end
  end

  describe "new_cases_per_day" do
    test "counts index phase" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index
            },
            start: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_new_cases_per_day)

      assert entries =
               StatisticsContext.list_new_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 18

      assert Enum.all?(
               entries,
               &(match?(%NewCasesPerDay{count: 0}, &1) or
                   match?(
                     %NewCasesPerDay{count: 1, type: :index, sub_type: nil, date: ^day_2},
                     &1
                   ))
             )
    end

    test "counts with inserted at" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        inserted_at: ~U[2020-10-12 13:16:00Z],
        phases: [
          %{
            details: %{
              __type__: :index
            }
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_new_cases_per_day)

      assert entries =
               StatisticsContext.list_new_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 18

      assert Enum.all?(
               entries,
               &(match?(%NewCasesPerDay{count: 0}, &1) or
                   match?(
                     %NewCasesPerDay{count: 1, type: :index, sub_type: nil, date: ^day_2},
                     &1
                   ))
             )
    end

    # test "counts possible index phase" do
    #   [day_1, day_2, day_3] =
    #     Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

    #   tenant = tenant_fixture()
    #   person = person_fixture(tenant)
    #   user = user_fixture()

    #   case_fixture(person, user, user, %{
    #     phases: [
    #       %{
    #         details: %{
    #           __type__: :possible_index,
    #           type: :travel
    #         },
    #         start: day_2
    #       }
    #     ]
    #   })

    #   execute_materialized_view_refresh(:statistics_new_cases_per_day)

    #   assert entries =
    #            StatisticsContext.list_new_cases_per_day(
    #              tenant,
    #              day_1,
    #              day_3
    #            )

    #   assert length(entries) == 18

    #   assert Enum.all?(
    #            entries,
    #            &(match?(%NewCasesPerDay{count: 0}, &1) or
    #                match?(
    #                  %NewCasesPerDay{
    #                    count: 1,
    #                    type: :possible_index,
    #                    sub_type: :travel,
    #                    date: ^day_2
    #                  },
    #                  &1
    #                ))
    #          )
    # end

    test "exports new cases per day" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index
            },
            start: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_new_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :new_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 25
      end)
    end
  end

  describe "active_hospitalization_cases_per_day" do
    test "lists hospitalization case with date" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()
      organisation = organisation_fixture()

      case_fixture(person, user, user, %{
        hospitalizations: [
          %{start: day_2, end: day_3, organisation_uuid: organisation.uuid}
        ]
      })

      execute_materialized_view_refresh(:statistics_active_hospitalization_cases_per_day)

      assert [
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_1},
               %ActiveHospitalizationCasesPerDay{count: 1, date: ^day_2},
               %ActiveHospitalizationCasesPerDay{count: 1, date: ^day_3},
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_4}
             ] =
               StatisticsContext.list_active_hospitalization_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "does not list case without hospitalization" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        hospitalizations: []
      })

      execute_materialized_view_refresh(:statistics_active_hospitalization_cases_per_day)

      assert [
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_1},
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_2},
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_3},
               %ActiveHospitalizationCasesPerDay{count: 0, date: ^day_4}
             ] =
               StatisticsContext.list_active_hospitalization_cases_per_day(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "exports active hospitalization cases per day" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()
      organisation = organisation_fixture()

      case_fixture(person, user, user, %{
        hospitalizations: [
          %{start: day_2, end: day_3, organisation_uuid: organisation.uuid}
        ]
      })

      execute_materialized_view_refresh(:statistics_active_hospitalization_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :active_hospitalization_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 5
      end)
    end
  end

  describe "active_complexity_cases_per_day" do
    test "counts high complexity cases from the end date" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        complexity: :high,
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_complexity_cases_per_day)

      assert entries =
               StatisticsContext.list_active_complexity_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(
               entries,
               &(match?(%ActiveComplexityCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveComplexityCasesPerDay{count: 1, case_complexity: :high, date: date}
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does count complexity nil" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        complexity: nil,
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: nil
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_complexity_cases_per_day)

      assert entries =
               StatisticsContext.list_active_complexity_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(
               entries,
               &(match?(%ActiveComplexityCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveComplexityCasesPerDay{count: 1, case_complexity: nil, date: date}
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does not count possible index" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        complexity: :medium,
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :contact_person,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_complexity_cases_per_day)

      assert entries =
               StatisticsContext.list_active_complexity_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 15

      assert Enum.all?(entries, &match?(%ActiveComplexityCasesPerDay{count: 0}, &1))
    end

    test "exports active complexity cases per day" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        complexity: :high,
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_complexity_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :active_complexity_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 21
      end)
    end
  end

  describe "active_infection_place_cases_per_day" do
    test "counts infection place other cases from the end date" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index,
                end_reason: :healed
              },
              start: day_2,
              end: day_2
            }
          ]
        })

      transmission_fixture(%{
        recipient_internal: true,
        recipient_case_uuid: index_case.uuid,
        infection_place: %{
          known: true,
          type: :other,
          type_other: "Bla Bla"
        }
      })

      execute_materialized_view_refresh(:statistics_active_infection_place_cases_per_day)

      assert entries =
               StatisticsContext.list_active_infection_place_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == (30 + 1) * 3

      assert Enum.all?(
               entries,
               &(match?(%ActiveInfectionPlaceCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveInfectionPlaceCasesPerDay{
                       count: 1,
                       infection_place_type: :other,
                       date: date
                     }
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "does count infection place nil" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: nil
            },
            start: day_2,
            end: day_2
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_infection_place_cases_per_day)

      assert entries =
               StatisticsContext.list_active_infection_place_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == (30 + 1) * 3

      assert Enum.all?(
               entries,
               &(match?(%ActiveInfectionPlaceCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveInfectionPlaceCasesPerDay{
                       count: 1,
                       infection_place_type: nil,
                       date: date
                     }
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "exports infection place cases" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index,
                end_reason: :healed
              },
              start: day_2,
              end: day_2
            }
          ]
        })

      transmission_fixture(%{
        recipient_internal: true,
        recipient_case_uuid: index_case.uuid,
        infection_place: %{
          known: true,
          type: :other,
          type_other: "Bla Bla"
        }
      })

      execute_materialized_view_refresh(:statistics_active_infection_place_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :active_infection_place_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 125
      end)
    end
  end

  describe "transmission_country_cases_per_day" do
    test "counts transmission country cases from the end date" do
      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index,
                end_reason: :healed
              },
              start: day_2,
              end: day_2
            }
          ]
        })

      transmission_fixture(%{
        recipient_internal: true,
        recipient_case_uuid: index_case.uuid,
        infection_place: %{
          address: %{
            address: "Torstrasse 25",
            zip: "9000",
            place: "St. Gallen",
            subdivision: "SG",
            country: "CH"
          },
          known: true
        }
      })

      execute_materialized_view_refresh(:statistics_transmission_country_cases_per_day)

      assert entries =
               StatisticsContext.list_transmission_country_cases_per_day(
                 tenant,
                 day_1,
                 day_3
               )

      assert length(entries) == 3

      assert Enum.all?(
               entries,
               &(match?(%TransmissionCountryCasesPerDay{count: 0}, &1) or
                   match?(
                     %TransmissionCountryCasesPerDay{
                       count: 1,
                       country: "CH",
                       date: date
                     }
                     when date in [day_2, day_3],
                     &1
                   ))
             )
    end

    test "exports transmission country cases" do
      [day_1, day_2, _day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index,
                end_reason: :healed
              },
              start: day_2,
              end: day_2
            }
          ]
        })

      transmission_fixture(%{
        recipient_internal: true,
        recipient_case_uuid: index_case.uuid,
        infection_place: %{
          address: %{
            address: "Torstrasse 25",
            zip: "9000",
            place: "St. Gallen",
            subdivision: "SG",
            country: "CH"
          },
          known: true
        }
      })

      execute_materialized_view_refresh(:statistics_transmission_country_cases_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :transmission_country_cases_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_4
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 5
      end)
    end
  end

  describe "active_cases_per_day_and_organisation" do
    test "list active cases per day and organisation" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      user = user_fixture()
      organisation1 = organisation_fixture()
      organisation1_name = organisation1.name
      organisation2 = organisation_fixture(%{name: "JMC"})
      organisation2_name = organisation2.name

      person1 = person_fixture(tenant)
      affiliation_fixture(person1, organisation1, %{kind: :employee})

      case_fixture(person1, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3,
            quarantine_order: true
          }
        ]
      })

      person2 = person_fixture(tenant)
      affiliation_fixture(person2, organisation1, %{kind: :employee})

      case_fixture(person2, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3,
            quarantine_order: true
          }
        ]
      })

      person3 = person_fixture(tenant)
      affiliation_fixture(person3, organisation2, %{kind: :employee})

      case_fixture(person3, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :index,
              end_reason: :healed
            },
            start: day_2,
            end: day_3,
            quarantine_order: true
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_cases_per_day_and_organisation)

      assert [
               %ActiveCasesPerDayAndOrganisation{
                 count: 2,
                 date: ^day_2,
                 organisation_name: ^organisation1_name
               },
               %ActiveCasesPerDayAndOrganisation{
                 count: 1,
                 date: ^day_2,
                 organisation_name: ^organisation2_name
               },
               %ActiveCasesPerDayAndOrganisation{
                 count: 2,
                 date: ^day_3,
                 organisation_name: ^organisation1_name
               },
               %ActiveCasesPerDayAndOrganisation{
                 count: 1,
                 date: ^day_3,
                 organisation_name: ^organisation2_name
               }
             ] =
               StatisticsContext.list_active_cases_per_day_and_organisation(
                 tenant,
                 day_1,
                 day_4
               )
    end

    test "does not list possible index" do
      [day_1, day_2, day_3, day_4] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -3), Date.utc_today()))

      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      affiliation_fixture(person, organisation_fixture(), %{kind: :employee})

      case_fixture(person, user, user, %{
        phases: [
          %{
            details: %{
              __type__: :possible_index,
              type: :contact_person,
              end_reason: :asymptomatic
            },
            start: day_2,
            end: day_3
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_cases_per_day_and_organisation)

      assert [] =
               StatisticsContext.list_active_cases_per_day_and_organisation(
                 tenant,
                 day_1,
                 day_4
               )
    end
  end

  describe "vaccination_breakthroughs_per_day" do
    test "counts positive cases with vaccination" do
      vaccine_one_date = Date.add(Date.utc_today(), -30)
      vaccine_two_date = Date.add(Date.utc_today(), -60)

      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()

      person =
        person_fixture(tenant, %{
          is_vaccinated: true,
          vaccination_shots: [
            %{vaccine_type: :moderna, date: vaccine_one_date},
            %{vaccine_type: :moderna, date: vaccine_two_date}
          ]
        })

      user = user_fixture()

      _index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index
              }
            }
          ],
          tests: [],
          clinical: %{
            symptom_start: day_2
          }
        })

      execute_materialized_view_refresh(:statistics_vaccination_breakthroughs_per_day)

      assert [
               %VaccinationBreakthroughsPerDay{count: 0, date: ^day_1},
               %VaccinationBreakthroughsPerDay{count: 1, date: ^day_2},
               %VaccinationBreakthroughsPerDay{count: 0, date: ^day_3}
             ] =
               StatisticsContext.list_vaccination_breakthroughs_per_day(
                 tenant,
                 day_1,
                 day_3
               )
    end

    test "exports breakthrough cases" do
      vaccine_one_date = Date.add(Date.utc_today(), -30)
      vaccine_two_date = Date.add(Date.utc_today(), -60)

      [day_1, day_2, day_3] =
        Enum.to_list(Date.range(Date.add(Date.utc_today(), -2), Date.utc_today()))

      tenant = tenant_fixture()

      person =
        person_fixture(tenant, %{
          is_vaccinated: true,
          vaccination_shots: [
            %{vaccine_type: :moderna, date: vaccine_one_date},
            %{vaccine_type: :moderna, date: vaccine_two_date}
          ]
        })

      user = user_fixture()

      _index_case =
        case_fixture(person, user, user, %{
          phases: [
            %{
              details: %{
                __type__: :index
              }
            }
          ],
          tests: [],
          clinical: %{
            symptom_start: day_2
          }
        })

      execute_materialized_view_refresh(:statistics_vaccination_breakthroughs_per_day)

      Repo.transaction(fn ->
        assert entries =
                 :vaccination_breakthroughs_per_day
                 |> StatisticsContext.export(
                   tenant,
                   day_1,
                   day_3
                 )
                 |> CSV.decode!(escape_formulas: true)
                 |> Enum.to_list()

        assert length(entries) == 4
      end)
    end
  end
end
