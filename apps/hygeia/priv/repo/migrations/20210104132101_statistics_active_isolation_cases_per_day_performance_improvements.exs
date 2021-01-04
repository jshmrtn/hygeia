# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsActiveIsolationCasesPerDayPerformanceImprovements do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop unique_index(:statistics_active_isolation_cases_per_day, [:tenant_uuid, :date])
    drop index(:statistics_active_isolation_cases_per_day, [:tenant_uuid])
    drop index(:statistics_active_isolation_cases_per_day, [:date])

    execute(
      """
      DROP MATERIALIZED VIEW statistics_active_isolation_cases_per_day;
      """,
      """
      CREATE MATERIALIZED VIEW statistics_active_isolation_cases_per_day
        (tenant_uuid, date, count)
        AS SELECT
          tenants.uuid, date::date, COUNT(
            DISTINCT
            CASE WHEN phase IS NULL THEN NULL ELSE people.uuid END
          ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          LEFT JOIN cases ON cases.tenant_uuid = tenants.uuid
          LEFT JOIN people ON people.uuid = cases.person_uuid
          LEFT JOIN UNNEST(cases.phases) AS phase
            ON (
              '{"details": {"__type__": "index"}}'::jsonb <@ (phase) AND
              COALESCE ((phase->>'start')::date, cases.inserted_at::date) <= date AND
              (
                  (phase->>'end')::date >= date OR (phase->>'end') IS NULL
              )
            )
          GROUP BY date, tenants.uuid
          ORDER BY date, tenants.uuid
      """
    )

    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_isolation_cases_per_day
        (tenant_uuid, date, count)
        AS
          WITH active_cases AS (
            SELECT
              cases.tenant_uuid AS cmp_tenant_uuid,
              cases.person_uuid AS cmp_person_uuid,
              cmp_date::date AS cmp_date
            FROM cases
            CROSS JOIN unnest(cases.phases) AS phase
            CROSS JOIN GENERATE_SERIES(
              COALESCE((phase.phase ->> 'start'::text)::date, cases.inserted_at::date),
              COALESCE((phase.phase ->> 'end'::text)::date, CURRENT_DATE::date),
              INTERVAL '1 day'
            ) AS cmp_date
            WHERE '{ "details": { "__type__": "index" } }'::jsonb <@ (phase)
          )
          SELECT
            tenants.uuid,
            date::date,
            COUNT(
              DISTINCT
              active_cases.cmp_person_uuid
            ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          LEFT JOIN active_cases
            ON active_cases.cmp_tenant_uuid = tenants.uuid AND
            active_cases.cmp_date = date
          GROUP BY date, tenants.uuid
          ORDER BY date, tenants.uuid
      """,
      """
      DROP MATERIALIZED VIEW statistics_active_isolation_cases_per_day;
      """
    )

    create unique_index(:statistics_active_isolation_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_isolation_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_isolation_cases_per_day, [:date])
  end
end
