# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsActiveComplexityCasesPerDayFix do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop unique_index(:statistics_active_complexity_cases_per_day, [
           :tenant_uuid,
           :date,
           :case_complexity
         ])

    execute(
      """
      DROP MATERIALIZED VIEW statistics_active_complexity_cases_per_day;
      """,
      """
      CREATE MATERIALIZED VIEW statistics_active_complexity_cases_per_day
        (tenant_uuid, date, case_complexity, count)
        AS WITH active_cases AS (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            cmp_date::date AS cmp_date,
            cases.complexity::case_complexity AS cmp_complexity
          FROM cases
          CROSS JOIN unnest(cases.phases) AS phase
          CROSS JOIN GENERATE_SERIES(
            COALESCE((phase.phase ->> 'start'::text)::date, cases.inserted_at::date),
            COALESCE((phase.phase ->> 'end'::text)::date, CURRENT_DATE::date),
            INTERVAL '1 day'
          ) AS cmp_date
          WHERE phase->'details'->>'__type__' = 'index'
      ) SELECT
          tenants.uuid,
          date::date,
          case_complexity,
          COUNT(DISTINCT active_cases.cmp_person_uuid) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_complexity) || ARRAY[NULL::case_complexity]) AS case_complexity
          LEFT JOIN active_cases ON
            active_cases.cmp_tenant_uuid = tenants.uuid AND
            active_cases.cmp_date = date AND
            active_cases.cmp_complexity = case_complexity.case_complexity
          GROUP BY date, tenants.uuid, case_complexity
          ORDER BY date, tenants.uuid, case_complexity
      """
    )

    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_complexity_cases_per_day
        (tenant_uuid, date, case_complexity, count)
        AS WITH active_cases AS (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            cmp_date::date AS cmp_date,
            cases.complexity::case_complexity AS cmp_complexity
          FROM cases
          CROSS JOIN unnest(cases.phases) AS phase
          CROSS JOIN GENERATE_SERIES(
            COALESCE((phase.phase ->> 'start'::text)::date, cases.inserted_at::date),
            COALESCE((phase.phase ->> 'end'::text)::date, CURRENT_DATE::date),
            INTERVAL '1 day'
          ) AS cmp_date
          WHERE phase->'details'->>'__type__' = 'index'
      ) SELECT
          tenants.uuid,
          date::date,
          case_complexity,
          COUNT(DISTINCT active_cases.cmp_person_uuid) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_complexity) || ARRAY[NULL::case_complexity]) AS case_complexity
          LEFT JOIN active_cases ON
            active_cases.cmp_tenant_uuid = tenants.uuid AND
            active_cases.cmp_date = date AND
            (
            active_cases.cmp_complexity = case_complexity.case_complexity OR
              (
                active_cases.cmp_complexity IS NULL AND case_complexity.case_complexity IS NULL
              )
            )
          GROUP BY date, tenants.uuid, case_complexity
          ORDER BY date, tenants.uuid, case_complexity
      """,
      """
      DROP MATERIALIZED VIEW statistics_active_complexity_cases_per_day;
      """
    )

    create unique_index(:statistics_active_complexity_cases_per_day, [
             :tenant_uuid,
             :date,
             :case_complexity
           ])

    create index(:statistics_active_complexity_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_complexity_cases_per_day, [:date])
    create index(:statistics_active_complexity_cases_per_day, [:case_complexity])
  end
end
