# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.InboxImportDefaultTracerSupervisor do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:imports) do
      add :default_tracer_uuid, references(:users), null: true
      add :default_supervisor_uuid, references(:users), null: true
    end

    execute(
      """
      CREATE FUNCTION check_user_authorization_on_import()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $check_user_authorization_on_import$
      BEGIN
        IF (
          NEW.default_tracer_uuid IS NOT NULL AND
          NOT EXISTS (
            SELECT * FROM user_grants
            WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
              user_grants.user_uuid = NEW.default_tracer_uuid AND
              user_grants.role = 'tracer'
          )
        ) THEN
          RAISE check_violation
            USING
              MESSAGE = 'user does not have tracer authorization on tenant',
              HINT = 'A user with a tracer authorization should be set into default_tracer_uuid.',
              CONSTRAINT = 'default_tracer_uuid',
              COLUMN = 'default_tracer_uuid',
              TABLE = TG_TABLE_NAME,
              SCHEMA = TG_TABLE_SCHEMA;
        END IF;
        IF (
          NEW.default_supervisor_uuid IS NOT NULL AND
          NOT EXISTS (
            SELECT * FROM user_grants
            WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
              user_grants.user_uuid = NEW.default_supervisor_uuid AND
              user_grants.role = 'supervisor'
          )
        ) THEN
          RAISE check_violation
            USING
              MESSAGE = 'user does not have supervisor authorization on tenant',
              HINT = 'A user with a tracer authorization should be set into default_supervisor_uuid.',
              CONSTRAINT = 'default_supervisor_uuid',
              COLUMN = 'default_supervisor_uuid',
              TABLE = TG_TABLE_NAME,
              SCHEMA = TG_TABLE_SCHEMA;
        END IF;
        RETURN NEW;
      END;
      $check_user_authorization_on_import$
      """,
      """
      DROP FUNCTION check_user_authorization_on_import;
      """
    )

    execute(
      """
      CREATE TRIGGER check_user_authorization_on_import
      BEFORE INSERT OR UPDATE
      ON imports
      FOR EACH ROW
      EXECUTE PROCEDURE check_user_authorization_on_import();
      """,
      """
      DROP TRIGGER check_user_authorization_on_import ON imports;
      """
    )
  end
end
