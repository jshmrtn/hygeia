# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VaccinationBreakthroughStatisticsPerformance do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.Repo.Migrations.CreateVaccinationShots

  case Code.ensure_compiled(CreateVaccinationShots) do
    {:module, CreateVaccinationShots} ->
      nil

    _other ->
      Code.require_file("20211230121753_create_vaccination_shots.exs", Path.dirname(__ENV__.file))
  end

  def up do
    drop unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    drop index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    drop index(:statistics_vaccination_breakthroughs_per_day, [:date])

    execute(
      """
      DROP
        MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
      """,
      CreateVaccinationShots.statistics_vaccination_breakthroughs_per_day_up_sql()
    )

    execute(
      """
      CREATE MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
        (tenant_uuid, date, count)
        AS
          WITH
            case_count_dates AS (
              SELECT
                cases.uuid AS uuid,
                cases.tenant_uuid AS tenant_uuid,
                cases.person_uuid AS person_uuid,
                COALESCE(
                  cases.last_test_date,
                  cases.case_index_last_known_date
                ) AS count_date
                FROM cases
                JOIN
                  UNNEST(cases.phases)
                  AS index_phases
                  ON index_phases->'details'->>'__type__' = 'index'
            )
          SELECT
            tenants.uuid AS tenant_uuid,
            date::date,
            COUNT(DISTINCT vaccination_shot_validity.person_uuid) AS count
            FROM GENERATE_SERIES(
              LEAST((SELECT MIN(count_date) from case_count_dates), CURRENT_DATE - INTERVAL '1 year'),
              CURRENT_DATE,
              interval '1 day'
            ) AS date
            CROSS JOIN tenants
            LEFT JOIN
              case_count_dates
              ON
                tenants.uuid = case_count_dates.tenant_uuid AND
                date = case_count_dates.count_date
            LEFT JOIN
              vaccination_shot_validity
              ON
                vaccination_shot_validity.range @> date::date AND
                vaccination_shot_validity.person_uuid = case_count_dates.person_uuid
            GROUP BY
              date,
              tenants.uuid
            ORDER BY
              date,
              tenants.uuid
      """,
      """
      DROP
        MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
      """
    )

    create unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    create index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    create index(:statistics_vaccination_breakthroughs_per_day, [:date])
  end
end
