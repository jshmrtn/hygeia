# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VaccinationValidityTriggerTable do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.Repo.Migrations.CreateVaccinationShots
  alias Hygeia.Repo.Migrations.VaccinationValidityCaseInfluence

  case Code.ensure_compiled(CreateVaccinationShots) do
    {:module, CreateVaccinationShots} ->
      nil

    _other ->
      Code.require_file("20211230121753_create_vaccination_shots.exs", Path.dirname(__ENV__.file))
  end

  case Code.ensure_compiled(VaccinationValidityCaseInfluence) do
    {:module, VaccinationValidityCaseInfluence} ->
      nil

    _other ->
      Code.require_file(
        "20220117182843_vaccination_validity_case_influence.exs",
        Path.dirname(__ENV__.file)
      )
  end

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    drop unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    drop index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    drop index(:statistics_vaccination_breakthroughs_per_day, [:date])

    execute("""
    DROP
      MATERIALIZED VIEW statistics_vaccination_breakthroughs_per_day
    """)

    execute("""
    DROP
      MATERIALIZED VIEW vaccination_shot_validity;
    """)

    execute("""
    DROP
      VIEW case_phase_dates;
    """)

    alter table(:cases) do
      add :first_test_date, :date, null: true
      add :last_test_date, :date, null: true
      add :case_index_first_known_date, :date, null: true
      add :case_index_last_known_date, :date, null: true
    end

    execute("""
    CREATE FUNCTION
      case_test_dates_update()
      RETURNS TRIGGER AS $$
        BEGIN
          UPDATE
            cases
            SET
              first_test_date = result.first_test_date,
              last_test_date = result.last_test_date
            FROM
              (
                SELECT
                  tests.case_uuid,
                  LEAST(
                    MIN(tests.tested_at),
                    MIN(tests.laboratory_reported_at)
                  )::date AS first_test_date,
                  GREATEST(
                    MAX(tests.tested_at),
                    MAX(tests.laboratory_reported_at)
                  )::date AS last_test_date
                  FROM tests
                  WHERE
                    tests.case_uuid = NEW.case_uuid OR
                    tests.case_uuid = OLD.case_uuid AND
                    tests.result = 'positive'
                  GROUP BY tests.case_uuid
              )
              AS result
            WHERE result.case_uuid = cases.uuid;

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      case_test_dates_updated
      AFTER INSERT OR UPDATE OR DELETE
      ON tests
      FOR EACH ROW EXECUTE PROCEDURE case_test_dates_update();
    """)

    execute("""
    CREATE FUNCTION
      case_index_known_dates_update()
      RETURNS TRIGGER AS $$
        BEGIN
        NEW.case_index_first_known_date = (
          SELECT
            (CASE
              WHEN COUNT(phase) > 0 THEN
                COALESCE(
                  LEAST(
                    NEW.first_test_date,
                    (NEW.clinical->>'symptom_start')::date,
                    MIN((phase->>'start')::date)
                  ),
                  MIN((phase->>'order_date')::date),
                  MIN((phase->>'inserted_at')::date)
                )
              END)::date
            FROM
              UNNEST(NEW.phases)
              AS phase
            WHERE
              phase->'details'->>'__type__' = 'index'
          );
          NEW.case_index_last_known_date = (
            SELECT
              (CASE
                WHEN COUNT(phase) > 0 THEN
                  COALESCE(
                    GREATEST(
                      NEW.last_test_date,
                      MAX((phase->>'end')::date),
                      (NEW.clinical->>'symptom_start')::date
                    ),
                    MAX((phase->>'order_date')::date),
                    MAX((phase->>'inserted_at')::date),
                    NEW.inserted_at
                  )
              END)::date
              FROM
                UNNEST(NEW.phases)
                AS phase
              WHERE
                phase->'details'->>'__type__' = 'index'
          );

          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      case_index_known_dates_updated_insert
      BEFORE INSERT
      ON cases
      FOR EACH ROW EXECUTE PROCEDURE case_index_known_dates_update();
    """)

    execute("""
    CREATE TRIGGER
      case_index_known_dates_updated_update
      BEFORE UPDATE
      ON cases
      FOR EACH ROW EXECUTE PROCEDURE case_index_known_dates_update();
    """)

    execute("""
    UPDATE
      cases
      SET
        first_test_date = result.first_test_date,
        last_test_date = result.last_test_date
      FROM
        (
          SELECT
            tests.case_uuid,
            LEAST(
              MIN(tests.tested_at),
              MIN(tests.laboratory_reported_at)
            )::date AS first_test_date,
            GREATEST(
              MAX(tests.tested_at),
              MAX(tests.laboratory_reported_at)
            )::date AS last_test_date
            FROM tests
            WHERE
              tests.result = 'positive'
            GROUP BY tests.case_uuid
        )
        AS result
      WHERE result.case_uuid = cases.uuid
    """)

    create index(:cases, :first_test_date)
    create index(:cases, :last_test_date)
    create index(:cases, :case_index_first_known_date)
    create index(:cases, :case_index_last_known_date)

    create table(:vaccination_shot_validity, primary_key: false) do
      add :person_uuid, references(:people, on_delete: :delete_all), null: false

      add :vaccination_shot_uuid, references(:vaccination_shots, on_delete: :delete_all),
        null: false

      add :range, :daterange, null: false
    end

    create unique_index(:vaccination_shot_validity, [:vaccination_shot_uuid, :range])

    create index(:vaccination_shot_validity, [:vaccination_shot_uuid])
    create index(:vaccination_shot_validity, [:range])
    create index(:vaccination_shot_validity, [:person_uuid])

    execute("""
    CREATE FUNCTION
      recalculate_vaccination_shot_validity_for_person(SUBJECT_UUID UUID)
      RETURNS VOID AS $$
        BEGIN
          DELETE FROM vaccination_shot_validity WHERE vaccination_shot_validity.person_uuid = SUBJECT_UUID;
          INSERT
            INTO vaccination_shot_validity
            (person_uuid, vaccination_shot_uuid, range)
            #{VaccinationValidityCaseInfluence.janssen_query("SUBJECT_UUID")}
            UNION
            #{VaccinationValidityCaseInfluence.moderna_pfizer_astra_combo_query("SUBJECT_UUID")}
            UNION
            #{VaccinationValidityCaseInfluence.double_query("SUBJECT_UUID")}
            UNION
            #{VaccinationValidityCaseInfluence.externally_convalescent_query("SUBJECT_UUID")}
            UNION
            #{internally_convalescent_query("SUBJECT_UUID")};
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE FUNCTION
      person_updated_recalculate_vaccination_shots()
      RETURNS TRIGGER AS $$
        BEGIN
          PERFORM recalculate_vaccination_shot_validity_for_person(NEW.uuid);
          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      person_updated_recalculate_vaccination_shots
      AFTER INSERT OR UPDATE
      ON people
      FOR EACH ROW EXECUTE PROCEDURE person_updated_recalculate_vaccination_shots();
    """)

    execute("""
    CREATE FUNCTION
      case_updated_recalculate_vaccination_shots()
      RETURNS TRIGGER AS $$
        BEGIN
          PERFORM recalculate_vaccination_shot_validity_for_person(COALESCE(NEW.person_uuid, OLD.person_uuid));
          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      person_updated_recalculate_vaccination_shots
      AFTER INSERT OR UPDATE OR DELETE
      ON cases
      FOR EACH ROW EXECUTE PROCEDURE case_updated_recalculate_vaccination_shots();
    """)

    execute("""
    CREATE FUNCTION
      vaccination_shot_updated_recalculate_vaccination_shots()
      RETURNS TRIGGER AS $$
        BEGIN
          PERFORM recalculate_vaccination_shot_validity_for_person(COALESCE(NEW.person_uuid, OLD.person_uuid));
          RETURN NEW;
        END
      $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER
      vaccination_shot_updated_recalculate_vaccination_shots
      AFTER INSERT OR UPDATE OR DELETE
      ON vaccination_shots
      FOR EACH ROW EXECUTE PROCEDURE vaccination_shot_updated_recalculate_vaccination_shots();
    """)

    for query <- [
          VaccinationValidityCaseInfluence.janssen_query(),
          VaccinationValidityCaseInfluence.moderna_pfizer_astra_combo_query(),
          VaccinationValidityCaseInfluence.double_query(),
          VaccinationValidityCaseInfluence.externally_convalescent_query(),
          internally_convalescent_query()
        ] do
      execute("""
      INSERT
        INTO vaccination_shot_validity
        (person_uuid, vaccination_shot_uuid, range)
        #{query}
        ON CONFLICT DO NOTHING;
      """)
    end

    execute(CreateVaccinationShots.statistics_vaccination_breakthroughs_per_day_up_sql())

    create unique_index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid, :date])

    create index(:statistics_vaccination_breakthroughs_per_day, [:tenant_uuid])
    create index(:statistics_vaccination_breakthroughs_per_day, [:date])
  end

  # 'astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin':
  # internally convalescent, no waiting period, valid 1 year
  defp internally_convalescent_query(person_uuid_expr \\ nil) do
    """
    SELECT
      result.person_uuid,
      result.vaccination_shot_uuid,
      result.range
      FROM (
        SELECT
          people.uuid AS person_uuid,
          vaccination_shots.uuid AS vaccination_shot_uuid,
          CASE
            -- case is more than 4 weeks old, first shot is valid
            WHEN (
              ROW_NUMBER() OVER (
                PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type
                ORDER BY vaccination_shots.date
              ) = 1 AND
              vaccination_shots.date > (cases.case_index_last_known_date + INTERVAL '4 week')::date
            ) THEN
              DATERANGE(
                vaccination_shots.date,
                (vaccination_shots.date + INTERVAL '1 year')::date
              )
            -- case is inside shot shot start + 4 weeks and shot validity end, shot is valid after case
            WHEN (
              ROW_NUMBER() OVER (
                PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type
                ORDER BY vaccination_shots.date
              ) = 1 AND
              cases.case_index_last_known_date
                BETWEEN
                  (vaccination_shots.date + INTERVAL '4 week')::date
                  AND (vaccination_shots.date + INTERVAL '1 year')::date
            ) THEN
              DATERANGE(
                cases.case_index_last_known_date,
                (cases.case_index_last_known_date + INTERVAL '1 year')::date
              )
          END AS range
          FROM people
          JOIN
            vaccination_shots
            ON vaccination_shots.person_uuid = people.uuid
          JOIN
            cases
            ON cases.person_uuid = people.uuid
          JOIN
            UNNEST(cases.phases)
            AS index_phases
            ON index_phases->'details'->>'__type__' = 'index'
          WHERE
            vaccination_shots.vaccine_type IN ('astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin')
            #{case person_uuid_expr do
      nil -> ""
      expr -> "AND vaccination_shots.person_uuid = #{expr}"
    end}
      ) AS result
      WHERE result.range IS NOT NULL
    """
  end
end
