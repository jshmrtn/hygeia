# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.PossibleIndexSubmissionNotification do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute(
      """
      CREATE FUNCTION
        possible_index_submission_notification()
        RETURNS trigger AS $$
          DECLARE
            AFFECTED_TRACER_UUID UUID;
          BEGIN
            SELECT tracer_uuid INTO AFFECTED_TRACER_UUID FROM cases WHERE uuid = NEW.case_uuid;
            IF NOT AFFECTED_TRACER_UUID IS NULL AND (AFFECTED_TRACER_UUID <> (NULLIF(CURRENT_SETTING('versioning.originator_id'), ''))::uuid OR CURRENT_SETTING('versioning.originator_id') = '') THEN
              INSERT INTO notifications
                (uuid, body, user_uuid, inserted_at, updated_at) VALUES
                (
                  MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
                  JSONB_BUILD_OBJECT('__type__', 'possible_index_submitted', 'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid, 'case_uuid', NEW.case_uuid, 'possible_index_submission_uuid', NEW.uuid),
                  AFFECTED_TRACER_UUID,
                  NOW(),
                  NOW()
                );
            END IF;

            RETURN NEW;
          END
        $$ LANGUAGE plpgsql;
      """,
      """
      DROP FUNCTION possible_index_submission_notification
      """
    )

    execute(
      """
      CREATE TRIGGER
        possible_index_submission_changed
        AFTER INSERT OR UPDATE ON possible_index_submissions
        FOR EACH ROW EXECUTE PROCEDURE possible_index_submission_notification();
      """,
      """
      DROP TRIGGER possible_index_submission_changed ON possible_index_submissions;
      """
    )
  end
end
