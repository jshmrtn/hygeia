# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsNewCasesPerDayPerformance do
  @moduledoc false

  use Hygeia, :migration

  # Only up on purpose
  def up do
    execute("""
    DROP MATERIALIZED VIEW statistics_new_cases_per_day;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_new_cases_per_day
      (tenant_uuid, type, sub_type, date, count)
      AS WITH phases AS (
        SELECT
          cases.tenant_uuid AS tenant_uuid,
          cases.person_uuid AS person_uuid,
          phase->'details'->>'__type__' AS count_type,
          (phase->'details'->>'type')::case_phase_possible_index_type AS count_sub_type,
          COALESCE((phase->>'start')::date, cases.inserted_at::date) AS count_date
          FROM cases
          CROSS JOIN UNNEST(cases.phases) AS phase
        )
        SELECT
          tenants.uuid,
          type,
          sub_type,
          date::date,
          COUNT(DISTINCT phases.person_uuid) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(count_date) from phases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ARRAY['index', 'possible_index']) AS type
          LEFT JOIN UNNEST(ENUM_RANGE(NULL::case_phase_possible_index_type)) AS sub_type
            ON type = 'possible_index'
          CROSS JOIN tenants
          LEFT JOIN phases ON (
            tenants.uuid = phases.tenant_uuid AND
            date = phases.count_date AND
            phases.count_type = type AND
            (
              (phases.count_sub_type IS NULL AND sub_type IS NULL) OR
              phases.count_sub_type = sub_type
            )
          )
          GROUP BY date, type, sub_type, tenants.uuid
          ORDER BY date, type, sub_type, tenants.uuid
    """)

    create unique_index(:statistics_new_cases_per_day, [:tenant_uuid, :date, :type, :sub_type])
    create index(:statistics_new_cases_per_day, [:tenant_uuid])
    create index(:statistics_new_cases_per_day, [:date])
    create index(:statistics_new_cases_per_day, [:type])
    create index(:statistics_new_cases_per_day, [:sub_type])
  end
end
