# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.StatisticsCummulativeIndexCaseEndReasonsPerformance do
  @moduledoc false

  use Hygeia, :migration

  # Only up on purpose
  def up do
    execute("""
    DROP MATERIALIZED VIEW statistics_cumulative_index_case_end_reasons;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_cumulative_index_case_end_reasons
      (tenant_uuid, date, end_reason, count)
      AS WITH phases AS (
        SELECT
          cases.tenant_uuid AS tenant_uuid,
          cases.person_uuid AS person_uuid,
          (phase->>'end')::date AS count_date,
          (phase->'details'->>'end_reason')::case_phase_index_end_reason AS count_end_reason
          FROM cases
          CROSS JOIN UNNEST(cases.phases) AS phase
          WHERE (
            (phase ->> 'end')::date IS NOT NULL AND
            phase -> 'details' ->> '__type__' = 'index'
          )
        )
        SELECT
          tenants.uuid,
          date::date,
          end_reason,
          SUM(COUNT(DISTINCT phases.person_uuid)) OVER (
            PARTITION BY end_reason, tenants.uuid
            ORDER BY date::date
          )::integer AS count
          FROM GENERATE_SERIES(
            LEAST((SELECT MIN(count_date) from phases), CURRENT_DATE - INTERVAL '1 year'),
            CURRENT_DATE,
            interval '1 day'
          ) AS date
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::case_phase_index_end_reason) || ARRAY[NULL::case_phase_index_end_reason]) AS end_reason
          CROSS JOIN tenants
          LEFT JOIN phases ON (
            tenants.uuid = phases.tenant_uuid AND
            date = phases.count_date AND
            (
              (end_reason IS NULL AND phases.count_end_reason IS NULL) OR
              end_reason = phases.count_end_reason
            )
          )
          GROUP BY date, end_reason, tenants.uuid
          ORDER BY date, end_reason, tenants.uuid
    """)

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
