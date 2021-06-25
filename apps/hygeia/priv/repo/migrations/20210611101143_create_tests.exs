# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateTests do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.ExternalReference.Type, as: ReferenceType
  alias Hygeia.CaseContext.Test.Kind
  alias Hygeia.CaseContext.Test.Result

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    ALTER TYPE #{Result.type()} ADD VALUE IF NOT EXISTS 'inconclusive' BEFORE 'positive';
    """)

    execute("""
    ALTER TYPE #{ReferenceType.type()} ADD VALUE IF NOT EXISTS 'ism_patient' BEFORE 'other';
    """)

    create table(:tests) do
      add :tested_at, :date, null: true
      add :laboratory_reported_at, :date, null: true
      add :kind, Kind.type(), null: false
      add :result, Result.type(), null: true
      add :sponsor, :map, null: true
      add :reporting_unit, :map
      add :case_uuid, references(:cases, on_delete: :delete_all), null: false
      add :reference, :string, null: true

      timestamps()
    end

    create index(:tests, [:case_uuid])

    execute("""
    CREATE TRIGGER
      tests_versioning_insert
      AFTER INSERT ON tests
      FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
    """)

    execute("""
    CREATE TRIGGER
      tests_versioning_update
      AFTER UPDATE ON tests
      FOR EACH ROW EXECUTE PROCEDURE versioning_update();
    """)

    execute("""
    CREATE TRIGGER
      tests_versioning_delete
      AFTER DELETE ON tests
      FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
    """)

    execute("""
    INSERT INTO
      tests
      ("uuid", "tested_at", "laboratory_reported_at", "kind", "result", "sponsor", "reporting_unit", "case_uuid", "reference", "inserted_at", "updated_at")
      SELECT
        MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
        (cases.clinical->>'test')::date,
        (cases.clinical->>'laboratory_report')::date,
        (cases.clinical->>'test_kind')::#{Kind.type()},
        (cases.clinical->>'result')::#{Result.type()},
        (cases.clinical->'sponsor'),
        (cases.clinical->'reporting_unit'),
        cases.uuid,
        NULL,
        NOW(),
        NOW()
      FROM cases
      WHERE
        (cases.clinical->>'test') IS NOT NULL AND
        (cases.clinical->>'test_kind') IS NOT NULL
    """)
  end
end
