# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsActiveQuarantineCasesPerDayPerformanceImprovements do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop unique_index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid, :date, :type])
    drop index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid])
    drop index(:statistics_active_quarantine_cases_per_day, [:date])
    drop index(:statistics_active_quarantine_cases_per_day, [:type])

    execute(
      """
      DROP MATERIALIZED VIEW statistics_active_quarantine_cases_per_day;
      """,
      """
      CREATE MATERIALIZED VIEW statistics_active_quarantine_cases_per_day
        (tenant_uuid, type, date, count)
        AS SELECT
          tenants.uuid, type, date::date, COUNT(
            DISTINCT
            CASE WHEN phase IS NULL THEN NULL ELSE people.uuid END
          ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_phase_possible_index_type)) AS type
          CROSS JOIN tenants
          LEFT JOIN cases ON cases.tenant_uuid = tenants.uuid
          LEFT JOIN people ON people.uuid = cases.person_uuid
          LEFT JOIN UNNEST(cases.phases) AS phase
            ON (
              '{"details": {"__type__": "possible_index"}}'::jsonb <@ (phase) AND
              (phase->'details'->>'type')::case_phase_possible_index_type = type AND
              COALESCE ((phase->>'start')::date, cases.inserted_at::date) <= date AND
              (
                  (phase->>'end')::date >= date OR (phase->>'end') IS NULL
              )
            )
          GROUP BY date, type, tenants.uuid
          ORDER BY date, type, tenants.uuid
      """
    )

    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_quarantine_cases_per_day
        (tenant_uuid, type, date, count)
        AS WITH active_cases AS (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (phase->'details'->>'type')::case_phase_possible_index_type AS cmp_type,
            cmp_date::date AS cmp_date
          FROM cases
          CROSS JOIN unnest(cases.phases) AS phase
          CROSS JOIN GENERATE_SERIES(
            COALESCE((phase.phase->>'start'::text)::date, cases.inserted_at::date),
            COALESCE((phase.phase->>'end'::text)::date, CURRENT_DATE::date),
            INTERVAL '1 day'
          ) AS cmp_date
          WHERE '{ "details": { "__type__": "possible_index" } }'::jsonb <@ (phase)
        ) SELECT
          tenants.uuid,
          type,
          date::date,
          COUNT(DISTINCT active_cases.cmp_person_uuid) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_phase_possible_index_type)) AS type
          CROSS JOIN tenants
          LEFT JOIN active_cases ON
             active_cases.cmp_tenant_uuid = tenants.uuid AND
             date = active_cases.cmp_date AND
             type = active_cases.cmp_type
          GROUP BY date, type, tenants.uuid
          ORDER BY date, type, tenants.uuid
      """,
      """
      DROP MATERIALIZED VIEW statistics_active_quarantine_cases_per_day;
      """
    )

    create unique_index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid, :date, :type])
    create index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_quarantine_cases_per_day, [:date])
    create index(:statistics_active_quarantine_cases_per_day, [:type])
  end
end
