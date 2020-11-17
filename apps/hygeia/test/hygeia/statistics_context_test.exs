# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule Hygeia.StatisticsContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Hygeia.StatisticsContext
  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay
  alias Hygeia.StatisticsContext.CumulativeIndexCaseEndReasons

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

      assert [
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 1,
                 date: ~D[2020-10-12],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 1,
                 date: ~D[2020-10-13],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :no_follow_up
               }
             ] =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )
    end

    test "does not count end_reason nil" do
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

      assert [
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :no_follow_up
               }
             ] =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
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

      assert [
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-11],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-12],
                 end_reason: :no_follow_up
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :healed
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :death
               },
               %CumulativeIndexCaseEndReasons{
                 count: 0,
                 date: ~D[2020-10-13],
                 end_reason: :no_follow_up
               }
             ] =
               StatisticsContext.list_cumulative_index_case_end_reasons(
                 tenant,
                 ~D[2020-10-11],
                 ~D[2020-10-13]
               )
    end
  end
end
