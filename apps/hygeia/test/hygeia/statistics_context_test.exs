defmodule Hygeia.StatisticsContextTest do
  @moduledoc false

  use Hygeia.DataCase

  alias Ecto.Adapters.SQL
  alias Hygeia.StatisticsContext
  alias Hygeia.StatisticsContext.ActiveIsolationCasesPerDay

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

      execute_refresh(:statistics_active_isolation_cases_per_day)

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

      execute_refresh(:statistics_active_isolation_cases_per_day)

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

      execute_refresh(:statistics_active_isolation_cases_per_day)

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

  defp execute_refresh(view) do
    SQL.query!(Hygeia.Repo, "REFRESH MATERIALIZED VIEW CONCURRENTLY #{view}")
  end
end
