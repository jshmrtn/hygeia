# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsActiveComplexityCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_complexity_cases_per_day
        (tenant_uuid, date, case_complexity, count)
        AS SELECT
          tenants.uuid, date::date, case_complexity, COUNT(
            DISTINCT
            CASE WHEN phase IS NULL THEN NULL ELSE people.uuid END
          ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_complexity) || ARRAY[NULL::case_complexity]) AS case_complexity
          LEFT JOIN cases ON cases.tenant_uuid = tenants.uuid
          LEFT JOIN people ON people.uuid = cases.person_uuid
          LEFT JOIN UNNEST(cases.phases) AS phase
            ON (
              COALESCE ((phase->>'start')::date, cases.inserted_at::date) <= date AND
              (
                  ((phase->>'end')::date >= date OR (phase->>'end') IS NULL) AND
                  phase -> 'details' ->> '__type__' = 'index'
              )  AND
              (
                cases.complexity::case_complexity = case_complexity OR
                (
                  case_complexity IS NULL AND cases.complexity IS NULL
                )
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
