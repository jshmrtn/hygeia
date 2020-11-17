# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsActiveIsolationCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
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
