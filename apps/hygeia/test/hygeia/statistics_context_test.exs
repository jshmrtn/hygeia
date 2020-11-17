# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule Hygeia.StatisticsContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.StatisticsContext
  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay
  alias Hygeia.StatisticsContext.ActiveQuarantineCasesPerDay
  alias Hygeia.StatisticsContext.CumulativeIndexCaseEndReasons
  alias Hygeia.StatisticsContext.CumulativePossibleIndexCaseEndReasons

  @moduletag origin: :test
  @moduletag originator: :noone

  describe "active_isolation_cases_per_day" do
    test "lists index case with date" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-13]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      assert [
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-11]},
               %ActiveIsolationCasesPerDay{count: 1, date: ~D[2020-10-12]},
               %ActiveIsolationCasesPerDay{count: 1, date: ~D[2020-10-13]},
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-14]}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )
    end

    test "lists index case with only inserted_at date" do
      tenant = tenant_fixture()
      person = person_fixture(tenant)
      user = user_fixture()

      case_fixture(person, user, user, %{
        inserted_at: ~U[2020-10-12 11:34:21.423847Z],
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
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-11]},
               %ActiveIsolationCasesPerDay{count: 1, date: ~D[2020-10-12]},
               %ActiveIsolationCasesPerDay{count: 1, date: ~D[2020-10-13]},
               %ActiveIsolationCasesPerDay{count: 1, date: ~D[2020-10-14]}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )
    end

    test "does not list case without index phase" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-13]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_isolation_cases_per_day)

      assert [
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-11]},
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-12]},
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-13]},
               %ActiveIsolationCasesPerDay{count: 0, date: ~D[2020-10-14]}
             ] =
               StatisticsContext.list_active_isolation_cases_per_day(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )
    end
  end

  describe "cumulative_index_case_end_reasons" do
    test "counts cases from the end date" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 12

      assert Enum.all?(
               entries,
               &(match?(%CumulativeIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativeIndexCaseEndReasons{count: 1, end_reason: :healed, date: date}
                     when date in [~D[2020-10-12], ~D[2020-10-13]],
                     &1
                   ))
             )
    end

    test "does count end_reason nil" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 12

      assert Enum.all?(
               entries,
               &(match?(%CumulativeIndexCaseEndReasons{count: 0}, &1) or
                   match?(
                     %CumulativeIndexCaseEndReasons{count: 1, end_reason: nil, date: date}
                     when date in [~D[2020-10-12], ~D[2020-10-13]],
                     &1
                   ))
             )
    end

    test "does not count possible index" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 12

      assert Enum.all?(entries, &match?(%CumulativeIndexCaseEndReasons{count: 0}, &1))
    end
  end

  describe "active_quarantine_cases_per_day" do
    test "lists index case with date" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-13]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      assert entries =
               StatisticsContext.list_active_quarantine_cases_per_day(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )

      assert length(entries) == 8

      assert Enum.all?(
               entries,
               &(match?(%ActiveQuarantineCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveQuarantineCasesPerDay{count: 1, type: :travel, date: date}
                     when date in [~D[2020-10-12], ~D[2020-10-13], ~D[2020-10-14]],
                     &1
                   ))
             )
    end

    test "lists index case with only inserted_at date" do
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
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )

      assert length(entries) == 8

      assert Enum.all?(
               entries,
               &(match?(%ActiveQuarantineCasesPerDay{count: 0}, &1) or
                   match?(
                     %ActiveQuarantineCasesPerDay{count: 1, type: :travel, date: date}
                     when date in [~D[2020-10-12], ~D[2020-10-13], ~D[2020-10-14]],
                     &1
                   ))
             )
    end

    test "does not list case without index phase" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-13]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_active_quarantine_cases_per_day)

      assert entries =
               StatisticsContext.list_active_quarantine_cases_per_day(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-14]
               )

      assert length(entries) == 8

      assert Enum.all?(entries, &match?(%ActiveQuarantineCasesPerDay{count: 0}, &1))
    end
  end

  describe "cumulative_possible_index_case_end_reasons" do
    test "counts cases from the end date" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 30

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
                     when date in [~D[2020-10-12], ~D[2020-10-13]],
                     &1
                   ))
             )
    end

    test "does count end_reason nil" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 30

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
                     when date in [~D[2020-10-12], ~D[2020-10-13]],
                     &1
                   ))
             )
    end

    test "does not count possible index" do
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
            start: ~D[2020-10-12],
            end: ~D[2020-10-12]
          }
        ]
      })

      execute_materialized_view_refresh(:statistics_cumulative_possible_index_case_end_reasons)

      assert entries =
               StatisticsContext.list_cumulative_possible_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )

      assert length(entries) == 30

      assert Enum.all?(entries, &match?(%CumulativePossibleIndexCaseEndReasons{count: 0}, &1))
    end
  end
end
