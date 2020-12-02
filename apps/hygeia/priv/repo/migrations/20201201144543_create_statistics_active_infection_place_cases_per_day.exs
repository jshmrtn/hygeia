# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateStatisticsActiveInfectionPlaceCasesPerDay do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE MATERIALIZED VIEW statistics_active_infection_place_cases_per_day
      (tenant_uuid, date, infection_place_type, count) AS
      WITH infection_place_types_with_null AS 
        (
          SELECT infection_place_types.uuid, infection_place_types.name 
          FROM infection_place_types 
          UNION SELECT NULL::uuid AS uuid, NULL::text AS name 
        ),
        person_date_infection_place AS 
        (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (transmissions.infection_place ->> 'type_uuid')::uuid AS cmp_infection_place_type_uuid,
            cmp_date::date 
          FROM cases 
          LEFT JOIN transmissions 
              ON transmissions.recipient_case_uuid = cases.uuid 
          CROSS JOIN UNNEST(cases.phases) AS phase 
          CROSS JOIN
            GENERATE_SERIES( COALESCE ((phase ->> 'start')::date, cases.inserted_at::date), COALESCE ((phase ->> 'end')::date, CURRENT_DATE), interval '1 day' ) AS cmp_date 
        )
      SELECT
        tenants.uuid,
        day::date AS date,
        infection_place_types_with_null.name AS infection_place_type,
        COUNT(DISTINCT person_date_infection_place.cmp_person_uuid) AS count 
      FROM
        GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) FROM cases), CURRENT_DATE - INTERVAL '1 year'), CURRENT_DATE, interval '1 day' ) AS day 
          CROSS JOIN tenants 
          CROSS JOIN infection_place_types_with_null 
          LEFT JOIN person_date_infection_place 
            ON ( tenants.uuid = person_date_infection_place.cmp_tenant_uuid 
              AND day = person_date_infection_place.cmp_date 
              AND (
                infection_place_types_with_null.uuid = person_date_infection_place.cmp_infection_place_type_uuid 
                OR 
                (
                  infection_place_types_with_null.uuid IS NULL 
                  AND person_date_infection_place.cmp_infection_place_type_uuid IS NULL
                )
              )
            ) 
        GROUP BY day, tenants.uuid, infection_place_type 
        ORDER BY day, tenants.uuid, infection_place_type
      """,
      """
      DROP MATERIALIZED VIEW statistics_active_infection_place_cases_per_day;
      """
    )

    create unique_index(:statistics_active_infection_place_cases_per_day, [
             :tenant_uuid,
             :date,
             :infection_place_type
           ])

    create index(:statistics_active_infection_place_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_infection_place_cases_per_day, [:date])
    create index(:statistics_active_infection_place_cases_per_day, [:infection_place_type])
  end
end
