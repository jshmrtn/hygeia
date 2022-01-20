# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VaccinationValidityCaseInfluence do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.Repo.Migrations.CreateVaccinationShots

  case Code.ensure_compiled(CreateVaccinationShots) do
    {:module, CreateVaccinationShots} ->
      nil

    _other ->
      Code.require_file("20211230121753_create_vaccination_shots.exs", Path.dirname(__ENV__.file))
  end

  def change do
    execute(
      """
      CREATE
        VIEW case_phase_dates
        AS
          SELECT
            cases.uuid AS case_uuid,
            (phase->>'uuid')::uuid AS phase_uuid,
            LEAST(
              MIN(tests.tested_at),
              MIN(tests.laboratory_reported_at)
            )::date AS first_test_date,
            GREATEST(
              MAX(tests.tested_at),
              MAX(tests.laboratory_reported_at)
            )::date AS last_test_date,
            COALESCE(
              LEAST(
                MIN(tests.tested_at),
                MIN(tests.laboratory_reported_at),
                (cases.clinical->>'symptom_start')::date,
                (phase->>'start')::date
              ),
              (phase->>'order_date')::date,
              (phase->>'inserted_at')::date,
              cases.inserted_at
            )::date AS case_first_known_date,
            COALESCE(
              GREATEST(
                MAX(tests.tested_at),
                MAX(tests.laboratory_reported_at),
                (phase->>'end')::date
              ),
              (phase->>'order_date')::date,
              (phase->>'inserted_at')::date,
              cases.inserted_at
            )::date AS case_last_known_date
            FROM cases
            CROSS JOIN
              UNNEST(cases.phases)
              AS phase
            LEFT JOIN
              tests
              ON
                tests.case_uuid = cases.uuid AND
                tests.result = 'positive'
            GROUP BY
              cases.uuid,
              phase
      """,
      """
        DROP
          VIEW case_phase_dates
      """
    )

    execute(
      """
      CREATE OR REPLACE
        VIEW vaccination_shot_validity
        AS #{vaccination_shot_validity_up_query()}
      """,
      """
      CREATE
        OR REPLACE
        VIEW vaccination_shot_validity
        AS #{CreateVaccinationShots.vaccination_shot_validity_up_query()}
      """
    )
  end

  def vaccination_shot_validity_up_query do
    """
    #{janssen_query()}
    UNION
    #{moderna_pfizer_astra_combo_query()}
    UNION
    #{double_query()}
    UNION
    #{externally_convalescent_query()}
    UNION
    #{internally_convalescent_query()}
    """
  end

  # janssen: min one vaccination, waiting period of 22 days, valid 1 year
  def janssen_query(person_uuid_expr \\ nil) do
    """
    SELECT
      vaccination_shots.person_uuid AS person_uuid,
      vaccination_shots.uuid AS vaccination_shot_uuid,
      DATERANGE(
        (vaccination_shots.date + INTERVAL '22 day')::date,
        (vaccination_shots.date + INTERVAL '1 year 22 day')::date
      ) AS range
      FROM vaccination_shots
      WHERE
        vaccination_shots.vaccine_type = 'janssen'
        #{case person_uuid_expr do
      nil -> ""
      expr -> "AND vaccination_shots.person_uuid = #{expr}"
    end}
    """
  end

  # 'moderna', 'pfizer', 'astra_zeneca':
  # valid if more than two combined, no waiting period, valid 1 year
  def moderna_pfizer_astra_combo_query(person_uuid_expr \\ nil) do
    """
    SELECT
      result.person_uuid,
      result.vaccination_shot_uuid,
      result.range
      FROM (
        SELECT
        vaccination_shots.person_uuid AS person_uuid,
          vaccination_shots.uuid AS vaccination_shot_uuid,
          CASE
            -- More than 2 vaccinations, shot is valid
            WHEN (
              ROW_NUMBER() OVER (
                PARTITION BY vaccination_shots.person_uuid
                ORDER BY vaccination_shots.date
              ) >= 2
            ) THEN
              DATERANGE(
                vaccination_shots.date,
                (vaccination_shots.date + INTERVAL '1 year')::date
              )
            ELSE NULL
          END AS range
          FROM vaccination_shots
          WHERE
            vaccination_shots.vaccine_type IN ('pfizer', 'moderna', 'astra_zeneca')
            #{case person_uuid_expr do
      nil -> ""
      expr -> "AND vaccination_shots.person_uuid = #{expr}"
    end}
      ) AS result
      WHERE result.range IS NOT NULL
    """
  end

  # 'astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac' 'covaxin':
  # min two, no waiting period, valid 1 year
  def double_query(person_uuid_expr \\ nil) do
    """
    SELECT
      result.person_uuid,
      result.vaccination_shot_uuid,
      result.range
      FROM (
        SELECT
        vaccination_shots.person_uuid AS person_uuid,
          vaccination_shots.uuid AS vaccination_shot_uuid,
          CASE
            -- More than 2 vaccinations, shot is valid
            WHEN (
              ROW_NUMBER() OVER (
                PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type
                ORDER BY vaccination_shots.date
              ) >= 2
            ) THEN
              DATERANGE(
                vaccination_shots.date,
                (vaccination_shots.date + INTERVAL '1 year')::date
              )
            ELSE NULL
          END AS range
          FROM vaccination_shots
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

  # 'astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin':
  # externally convalescent, no waiting period, valid 1 year
  def externally_convalescent_query(person_uuid_expr \\ nil) do
    """
    SELECT
      result.person_uuid,
      result.vaccination_shot_uuid,
      result.range
      FROM (
        SELECT
          vaccination_shots.person_uuid AS person_uuid,
          vaccination_shots.uuid AS vaccination_shot_uuid,
          CASE
            WHEN (
              ROW_NUMBER() OVER (
                PARTITION BY vaccination_shots.person_uuid, vaccination_shots.vaccine_type
                ORDER BY vaccination_shots.date
              ) = 1
            ) THEN
              DATERANGE(
                vaccination_shots.date,
                (vaccination_shots.date + INTERVAL '1 year')::date
              )
            ELSE NULL
          END AS range
          FROM people
          JOIN
            vaccination_shots
            ON vaccination_shots.person_uuid = people.uuid
          WHERE
            people.convalescent_externally AND
            vaccination_shots.vaccine_type IN ('astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin')
            #{case person_uuid_expr do
      nil -> ""
      expr -> "AND vaccination_shots.person_uuid = #{expr}"
    end}
      ) AS result
      WHERE result.range IS NOT NULL
    """
  end

  # 'astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin':
  # internally convalescent, no waiting period, valid 1 year
  defp internally_convalescent_query do
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
              vaccination_shots.date > (case_phase_dates.case_last_known_date + INTERVAL '4 week')::date
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
              case_phase_dates.case_last_known_date
                BETWEEN
                  (vaccination_shots.date + INTERVAL '4 week')::date
                  AND (vaccination_shots.date + INTERVAL '1 year')::date
            ) THEN
              DATERANGE(
                case_phase_dates.case_last_known_date,
                (case_phase_dates.case_last_known_date + INTERVAL '1 year')::date
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
          JOIN
            case_phase_dates
            ON
              case_phase_dates.case_uuid = cases.uuid AND
              case_phase_dates.phase_uuid = (index_phases->>'uuid')::uuid
          WHERE vaccination_shots.vaccine_type IN ('astra_zeneca', 'pfizer', 'moderna', 'sinopharm', 'sinovac', 'covaxin')
      ) AS result
      WHERE result.range IS NOT NULL
    """
  end
end
