# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsCumulativeIndexCaseEndReasons do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE MATERIALIZED VIEW statistics_cumulative_index_case_end_reasons
        (tenant_uuid, date, end_reason, count)
        AS SELECT
          tenants.uuid, date::date, end_reason, COUNT(
            DISTINCT
            CASE WHEN phase IS NULL THEN NULL ELSE cases.uuid END
          ) AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_phase_index_end_reason) || ARRAY[NULL::case_phase_index_end_reason]) AS end_reason
          LEFT JOIN cases ON cases.tenant_uuid = tenants.uuid
          LEFT JOIN people ON people.uuid = cases.person_uuid
          LEFT JOIN UNNEST(cases.phases) AS phase
            ON (
              '{"details": {"__type__": "index"}}'::jsonb <@ (phase) AND
              (phase->>'end')::date <= date AND
              (
                (phase->'details'->>'end_reason')::case_phase_index_end_reason = end_reason OR
                (
                  end_reason IS NULL AND (phase->'details'->>'end_reason') IS NULL
                )
              )
            )
          GROUP BY date, tenants.uuid, end_reason
          ORDER BY date, tenants.uuid, end_reason
      """,
      """
      DROP MATERIALIZED VIEW statistics_cumulative_index_case_end_reasons;
      """
    )

    create unique_index(:statistics_cumulative_index_case_end_reasons, [
             :tenant_uuid,
             :date,
             :end_reason
           ])

    create index(:statistics_cumulative_index_case_end_reasons, [:tenant_uuid])
    create index(:statistics_cumulative_index_case_end_reasons, [:end_reason])
    create index(:statistics_cumulative_index_case_end_reasons, [:date])
  end
end
