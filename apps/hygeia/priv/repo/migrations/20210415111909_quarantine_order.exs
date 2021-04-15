# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.QuarantineOrder do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    UPDATE
        cases AS update_case
    SET
        phases = array_replace(
            update_case.phases,
            subquery.search_phase,
            subquery.update_phase
        )
    FROM
        (
            SELECT
                cases.uuid AS case_uuid,
                ORDINALITY AS phase_index,
                phase AS search_phase,
                CASE
                  WHEN
                    (
                      phase->>'start' IS NOT NULL AND
                      phase->>'end' IS NOT NULL AND
                      (
                        phase->'details'->>'__type__' = 'index' OR
                        phase->'details'->>'type' IN ('travel', 'contact_person')
                      )
                    )
                    THEN phase || '{"quarantine_order": true}'::jsonb
                  WHEN
                    (
                      phase->'details'->>'__type__' = 'possible_index' OR
                      phase->'details'->>'type' NOT IN ('travel', 'contact_person')
                    )
                    THEN phase || '{"quarantine_order": false, "start": null, "end": null}'::jsonb
                  ELSE phase || '{"start": null, "end": null}'::jsonb
                END AS update_phase
            FROM cases
            CROSS JOIN
                UNNEST(cases.phases)
                WITH ORDINALITY
                AS phase
        ) AS subquery
    WHERE
          update_case.uuid = subquery.case_uuid
    """)

    execute("""
    DROP MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation
      (tenant_uuid, date, organisation_uuid, count)
      AS
      WITH ranked_active_cases AS (
        SELECT
          date::date AS date,
          cases.tenant_uuid AS tenant_uuid,
          affiliations.organisation_uuid AS organisation_uuid,
          COUNT(cases.person_uuid) AS count,
          ROW_NUMBER() OVER (PARTITION BY date, tenant_uuid ORDER BY COUNT(cases.person_uuid) DESC)
        FROM cases
        CROSS JOIN unnest(cases.phases) AS phase
        CROSS JOIN GENERATE_SERIES(
          (phase.phase ->> 'start'::text)::date,
          (phase.phase ->> 'end'::text)::date,
          INTERVAL '1 day'
        ) AS date
        LEFT JOIN affiliations
          ON affiliations.person_uuid = cases.person_uuid
        WHERE '{ "details": { "__type__": "index" }, "quarantine_order": true }'::jsonb <@ (phase)
        GROUP BY tenant_uuid, date, organisation_uuid
        HAVING COUNT(cases.person_uuid) > 0
        ORDER BY date, tenant_uuid, count DESC
      )
      SELECT tenant_uuid, date, organisation_uuid, count
      FROM ranked_active_cases
      WHERE row_number <= 100
    """)

    create unique_index(:statistics_active_cases_per_day_and_organisation, [
             :tenant_uuid,
             :date,
             :organisation_uuid
           ])

    create index(:statistics_active_cases_per_day_and_organisation, [:tenant_uuid])
    create index(:statistics_active_cases_per_day_and_organisation, [:date])

    create index(:statistics_active_cases_per_day_and_organisation, [:organisation_uuid])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_complexity_cases_per_day;
    """)

    execute("""
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
          (phase.phase ->> 'start'::text)::date,
          (phase.phase ->> 'end'::text)::date,
          INTERVAL '1 day'
        ) AS cmp_date
        WHERE '{ "details": { "__type__": "index" }, "quarantine_order": true }'::jsonb <@ (phase)
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
    """)

    create unique_index(:statistics_active_complexity_cases_per_day, [
             :tenant_uuid,
             :date,
             :case_complexity
           ])

    create index(:statistics_active_complexity_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_complexity_cases_per_day, [:date])
    create index(:statistics_active_complexity_cases_per_day, [:case_complexity])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day;
    """)

    execute("""
      CREATE MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day
        (tenant_uuid, date, count)
        AS WITH cases_with_hospitalizations AS (
          SELECT
            cases.tenant_uuid,
            cases.person_uuid,
            (hospitalization->>'start')::date AS start_date,
            COALESCE(
              (hospitalization->>'end')::date,
              CURRENT_DATE
            ) AS end_date
          FROM cases
          CROSS JOIN UNNEST(cases.hospitalizations) AS hospitalization
        )
        SELECT
          tenants.uuid,
          date::date,
          COUNT(DISTINCT cases_with_hospitalizations.person_uuid) AS count
        FROM GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
          CURRENT_DATE,
          interval '1 day'
        ) AS date
        CROSS JOIN tenants
        LEFT JOIN cases_with_hospitalizations
          ON (
            tenants.uuid = cases_with_hospitalizations.tenant_uuid AND
            cases_with_hospitalizations.end_date >= date AND
            cases_with_hospitalizations.start_date <= date
          )
        GROUP BY date, tenants.uuid
        ORDER BY date, tenants.uuid
    """)

    create unique_index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_hospitalization_cases_per_day, [:date])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_infection_place_cases_per_day;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_infection_place_cases_per_day
      (tenant_uuid, date, infection_place_type, count) AS
      WITH person_date_infection_place AS
        (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (transmissions.infection_place->>'type')::infection_place_type AS cmp_infection_place_type,
            cmp_date::date
          FROM cases
          LEFT JOIN transmissions
              ON transmissions.recipient_case_uuid = cases.uuid
          CROSS JOIN UNNEST(cases.phases) AS phase
          CROSS JOIN
            GENERATE_SERIES(
              (phase ->> 'start')::date,
              (phase ->> 'end')::date,
              interval '1 day'
            ) AS cmp_date
          WHERE '{ "details": { "__type__": "index" }, "quarantine_order": true }'::jsonb <@ (phase)
        )
      SELECT
        tenants.uuid,
        day::date AS date,
        infection_place_type,
        COUNT(DISTINCT person_date_infection_place.cmp_person_uuid) AS count
      FROM
        GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) FROM cases), CURRENT_DATE - INTERVAL '1 year'), CURRENT_DATE, interval '1 day' ) AS day
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::infection_place_type) || ARRAY[NULL::infection_place_type]) AS infection_place_type
          LEFT JOIN person_date_infection_place
            ON ( tenants.uuid = person_date_infection_place.cmp_tenant_uuid
              AND day = person_date_infection_place.cmp_date
              AND (
                infection_place_type = person_date_infection_place.cmp_infection_place_type
                OR
                (
                  infection_place_type IS NULL
                  AND person_date_infection_place.cmp_infection_place_type IS NULL
                )
              )
            )
        GROUP BY day, tenants.uuid, infection_place_type
        ORDER BY day, tenants.uuid, infection_place_type
    """)

    create unique_index(:statistics_active_infection_place_cases_per_day, [
             :tenant_uuid,
             :date,
             :infection_place_type
           ])

    create index(:statistics_active_infection_place_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_infection_place_cases_per_day, [:date])
    create index(:statistics_active_infection_place_cases_per_day, [:infection_place_type])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_isolation_cases_per_day;
    """)

    execute("""
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
            (phase.phase ->> 'start'::text)::date,
            (phase.phase ->> 'end'::text)::date,
            INTERVAL '1 day'
          ) AS cmp_date
          WHERE '{ "details": { "__type__": "index" }, "quarantine_order": true }'::jsonb <@ (phase)
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
    """)

    create unique_index(:statistics_active_isolation_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_isolation_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_isolation_cases_per_day, [:date])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_quarantine_cases_per_day;
    """)

    execute("""
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
          (phase.phase->>'start'::text)::date,
          (phase.phase->>'end'::text)::date,
          INTERVAL '1 day'
        ) AS cmp_date
        WHERE '{ "details": { "__type__": "possible_index" }, "quarantine_order": true }'::jsonb <@ (phase)
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
    """)

    create unique_index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid, :date, :type])
    create index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_quarantine_cases_per_day, [:date])
    create index(:statistics_active_quarantine_cases_per_day, [:type])
  end

  def down do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    UPDATE
        cases AS update_case
    SET
        phases = array_replace(
            update_case.phases,
            subquery.search_phase,
            subquery.update_phase
        )
    FROM
        (
            SELECT
                cases.uuid AS case_uuid,
                ORDINALITY AS phase_index,
                phase AS search_phase,
                (phase - 'quarantine_order') AS update_phase
            FROM cases
            CROSS JOIN
                UNNEST(cases.phases)
                WITH ORDINALITY
                AS phase
        ) AS subquery
    WHERE
          update_case.uuid = subquery.case_uuid
    """)

    execute("""
    DROP MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_cases_per_day_and_organisation
      (tenant_uuid, date, organisation_uuid, count)
      AS
      WITH ranked_active_cases AS (
        SELECT
          date::date AS date,
          cases.tenant_uuid AS tenant_uuid,
          affiliations.organisation_uuid AS organisation_uuid,
          COUNT(cases.person_uuid) AS count,
          ROW_NUMBER() OVER (PARTITION BY date, tenant_uuid ORDER BY COUNT(cases.person_uuid) DESC)
        FROM cases
        CROSS JOIN unnest(cases.phases) AS phase
        CROSS JOIN GENERATE_SERIES(
          COALESCE((phase.phase ->> 'start'::text)::date, cases.inserted_at::date),
          COALESCE((phase.phase ->> 'end'::text)::date, CURRENT_DATE::date),
          INTERVAL '1 day'
        ) AS date
        LEFT JOIN affiliations
          ON affiliations.person_uuid = cases.person_uuid
        WHERE phase->'details'->>'__type__' = 'index'
        GROUP BY tenant_uuid, date, organisation_uuid
        HAVING COUNT(cases.person_uuid) > 0
        ORDER BY date, tenant_uuid, count DESC
      )
      SELECT tenant_uuid, date, organisation_uuid, count
      FROM ranked_active_cases
      WHERE row_number <= 100
    """)

    create unique_index(:statistics_active_cases_per_day_and_organisation, [
             :tenant_uuid,
             :date,
             :organisation_uuid
           ])

    create index(:statistics_active_cases_per_day_and_organisation, [:tenant_uuid])
    create index(:statistics_active_cases_per_day_and_organisation, [:date])

    create index(:statistics_active_cases_per_day_and_organisation, [:organisation_uuid])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_complexity_cases_per_day;
    """)

    execute("""
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
    """)

    create unique_index(:statistics_active_complexity_cases_per_day, [
             :tenant_uuid,
             :date,
             :case_complexity
           ])

    create index(:statistics_active_complexity_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_complexity_cases_per_day, [:date])
    create index(:statistics_active_complexity_cases_per_day, [:case_complexity])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day;
    """)

    execute("""
      CREATE MATERIALIZED VIEW statistics_active_hospitalization_cases_per_day
        (tenant_uuid, date, count)
        AS WITH cases_with_hospitalizations AS (
          SELECT
            cases.tenant_uuid,
            cases.person_uuid,
            (hospitalization->>'start')::date AS start_date,
            COALESCE(
              (hospitalization->>'end')::date,
              (cases.phases[ARRAY_UPPER(cases.phases,1)]->>'end')::date,
              CURRENT_DATE
            ) AS end_date
          FROM cases
          CROSS JOIN UNNEST(cases.hospitalizations) AS hospitalization
        )
        SELECT
          tenants.uuid,
          date::date,
          COUNT(DISTINCT cases_with_hospitalizations.person_uuid) AS count
        FROM GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) from cases), CURRENT_DATE - INTERVAL '1 year'),
          CURRENT_DATE,
          interval '1 day'
        ) AS date
        CROSS JOIN tenants
        LEFT JOIN cases_with_hospitalizations
          ON (
            tenants.uuid = cases_with_hospitalizations.tenant_uuid AND
            cases_with_hospitalizations.end_date >= date AND
            cases_with_hospitalizations.start_date <= date
          )
        GROUP BY date, tenants.uuid
        ORDER BY date, tenants.uuid
    """)

    create unique_index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_hospitalization_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_hospitalization_cases_per_day, [:date])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_infection_place_cases_per_day;
    """)

    execute("""
    CREATE MATERIALIZED VIEW statistics_active_infection_place_cases_per_day
      (tenant_uuid, date, infection_place_type, count) AS
      WITH person_date_infection_place AS
        (
          SELECT
            cases.tenant_uuid AS cmp_tenant_uuid,
            cases.person_uuid AS cmp_person_uuid,
            (transmissions.infection_place->>'type')::infection_place_type AS cmp_infection_place_type,
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
        infection_place_type,
        COUNT(DISTINCT person_date_infection_place.cmp_person_uuid) AS count
      FROM
        GENERATE_SERIES(
          LEAST((SELECT MIN(inserted_at::date) FROM cases), CURRENT_DATE - INTERVAL '1 year'), CURRENT_DATE, interval '1 day' ) AS day
          CROSS JOIN tenants
          CROSS JOIN UNNEST(ENUM_RANGE(NULL::infection_place_type) || ARRAY[NULL::infection_place_type]) AS infection_place_type
          LEFT JOIN person_date_infection_place
            ON ( tenants.uuid = person_date_infection_place.cmp_tenant_uuid
              AND day = person_date_infection_place.cmp_date
              AND (
                infection_place_type = person_date_infection_place.cmp_infection_place_type
                OR
                (
                  infection_place_type IS NULL
                  AND person_date_infection_place.cmp_infection_place_type IS NULL
                )
              )
            )
        GROUP BY day, tenants.uuid, infection_place_type
        ORDER BY day, tenants.uuid, infection_place_type
    """)

    create unique_index(:statistics_active_infection_place_cases_per_day, [
             :tenant_uuid,
             :date,
             :infection_place_type
           ])

    create index(:statistics_active_infection_place_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_infection_place_cases_per_day, [:date])
    create index(:statistics_active_infection_place_cases_per_day, [:infection_place_type])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_isolation_cases_per_day;
    """)

    execute("""
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
    """)

    create unique_index(:statistics_active_isolation_cases_per_day, [:tenant_uuid, :date])
    create index(:statistics_active_isolation_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_isolation_cases_per_day, [:date])

    execute("""
    DROP MATERIALIZED VIEW statistics_active_quarantine_cases_per_day;
    """)

    execute("""
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
    """)

    create unique_index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid, :date, :type])
    create index(:statistics_active_quarantine_cases_per_day, [:tenant_uuid])
    create index(:statistics_active_quarantine_cases_per_day, [:date])
    create index(:statistics_active_quarantine_cases_per_day, [:type])
  end
end
