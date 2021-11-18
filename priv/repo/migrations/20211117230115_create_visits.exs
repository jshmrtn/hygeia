# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateVisits do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Visit.Reason

  def change do
    Reason.create_type()

    create table(:visits) do
      add :visit_reason, Reason.type()
      add :other_reason, :string
      add :last_visit_at, :utc_datetime

      add :person_uuid, references(:people, on_delete: :delete_all), null: false

      add :known_organisation_uuid, references(:organisations, on_delete: :nothing, type: :binary_id),
        null: true
      add :unknown_organisation, :map

      add :known_division_uuid, references(:divisions, on_delete: :nothing, type: :binary_id),
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
  end
end
