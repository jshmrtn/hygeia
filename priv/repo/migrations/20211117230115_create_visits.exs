# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateVisits do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Step
  alias Hygeia.OrganisationContext.Visit.Reason

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    Reason.create_type()

    create table(:visits) do
      add :reason, Reason.type()
      add :other_reason, :string
      add :last_visit_at, :date

      add :person_uuid, references(:people, on_delete: :delete_all), null: false

      add :organisation_uuid,
          references(:organisations, on_delete: :delete_all, type: :binary_id),
          null: true

      add :unknown_organisation, :map

      add :division_uuid, references(:divisions, on_delete: :nilify_all, type: :binary_id),
        null: true

      add :unknown_division, :map

      timestamps()
    end

    execute(
      """
      CREATE TRIGGER
        visit_versioning_insert
        AFTER INSERT ON visits
        FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
      """,
      """
      DROP TRIGGER visit_versioning_insert ON visits;
      """
    )

    execute(
      """
      CREATE TRIGGER
        visit_versioning_update
        AFTER UPDATE ON visits
        FOR EACH ROW EXECUTE PROCEDURE versioning_update();
      """,
      """
      DROP TRIGGER visit_versioning_update ON visits;
      """
    )

    execute(
      """
      CREATE TRIGGER
        visit_versioning_delete
        AFTER DELETE ON visits
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """,
      """
      DROP TRIGGER visit_versioning_delete ON visits;
      """
    )

    execute(
      """
        ALTER TYPE
        #{Step.type()}
        ADD VALUE IF NOT EXISTS 'visits' AFTER 'contact_methods';
      """,
      &noop/0
    )

    execute(
      """
        ALTER TABLE affiliations
        RENAME COLUMN related_school_visit_uuid TO related_visit_uuid;
      """,
      &noop/0
    )

    execute(
      """
      INSERT
        INTO visits
        (uuid, reason, other_reason, last_visit_at, person_uuid, organisation_uuid, unknown_organisation, division_uuid, unknown_division, inserted_at, updated_at)
        SELECT
          (school_visit->>'uuid')::uuid,
          (school_visit->>'visit_reason')::#{Reason.type()},
          school_visit->>'other_reason',
          (school_visit->>'visited_at')::date,
          cases.person_uuid,
          organisation.uuid,
          school_visit->'unknown_school',
          division.uuid,
          school_visit->'unknown_division',
          NOW(),
          NOW()
          FROM
            auto_tracings
            AS auto_tracing
          CROSS JOIN
            UNNEST(auto_tracing.school_visits)
            AS school_visit
          JOIN
            cases
            ON cases.uuid = auto_tracing.case_uuid
          LEFT JOIN
            organisations
            AS organisation
            ON organisation.uuid = (school_visit->>'known_school_uuid')::uuid
          LEFT JOIN
            divisions
            AS division
            ON division.uuid = (school_visit->>'known_division_uuid')::uuid
          WHERE
            organisation.uuid IS NOT NULL OR
            school_visit->>'unknown_school' IS NOT NULL
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :school_visits, {:array, :map}
    end

    execute(&noop/0, fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)
  end

  defp noop, do: :ok
end
