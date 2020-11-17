# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsActiveQuarantineCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
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
