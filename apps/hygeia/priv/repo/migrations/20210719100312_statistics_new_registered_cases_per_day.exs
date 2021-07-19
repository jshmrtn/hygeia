# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsNewRegisteredCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute("""
    CREATE MATERIALIZED VIEW statistics_new_registered_cases_per_day
      (tenant_uuid, type, date, first_contact, count)
      AS WITH phases AS (
        SELECT
          cases.tenant_uuid AS tenant_uuid,
          cases.person_uuid AS person_uuid,
          phase->'details'->>'__type__' AS count_type,
          COALESCE((phase->>'inserted_at')::date, cases.inserted_at::date) AS count_date,
          cases.status = 'first_contact' AS first_contact
          FROM cases
          CROSS JOIN UNNEST(cases.phases) AS phase
        )
        SELECT
          tenants.uuid,
          type,
          date::date,
          first_contact,
          COUNT(DISTINCT phases) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(count_date) from phases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ARRAY['index', 'possible_index']) AS type
          CROSS JOIN tenants
          LEFT JOIN phases ON (
            tenants.uuid = phases.tenant_uuid AND
            date = phases.count_date AND
            phases.count_type = type
          )
          GROUP BY first_contact, date, type, tenants.uuid
          ORDER BY first_contact, date, type, tenants.uuid
    """)

    create unique_index(:statistics_new_registered_cases_per_day, [
             :tenant_uuid,
             :date,
             :type,
             :first_contact
           ])

    create index(:statistics_new_registered_cases_per_day, [:tenant_uuid])
    create index(:statistics_new_registered_cases_per_day, [:date])
    create index(:statistics_new_registered_cases_per_day, [:type])
    create index(:statistics_new_registered_cases_per_day, [:first_contact])
  end
end
