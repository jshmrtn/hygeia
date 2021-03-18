# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateTriggerCaseAuthorizations do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE FUNCTION check_user_authorization_on_case()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $check_user_authorization_on_case$
      BEGIN
        IF NOT EXISTS (
          SELECT * FROM user_grants
          WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
            user_grants.user_uuid = NEW.tracer_uuid AND
            user_grants.role = 'tracer'
          ) THEN
          NEW.tracer_uuid = NULL;
        END IF;
        IF NOT EXISTS (
          SELECT * FROM user_grants
          WHERE user_grants.tenant_uuid = NEW.tenant_uuid AND
            user_grants.user_uuid = NEW.supervisor_uuid AND
            user_grants.role = 'supervisor'
          ) THEN
          NEW.supervisor_uuid = NULL;
        END IF;
        RETURN NEW;
      END;
      $check_user_authorization_on_case$
      """,
      """
      DROP FUNCTION check_user_authorization_on_case;
      """
    )

    execute(
      """
      CREATE TRIGGER check_user_authorization_on_case
      BEFORE INSERT OR UPDATE
      ON cases
      FOR EACH ROW
      EXECUTE PROCEDURE check_user_authorization_on_case();
      """,
      """
      DROP TRIGGER check_user_authorization_on_case ON cases;
      """
    )
  end
end
