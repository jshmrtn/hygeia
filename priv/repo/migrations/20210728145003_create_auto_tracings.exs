# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Problem
  alias Hygeia.AutoTracingContext.AutoTracing.Step

  def change do
    Step.create_type()
    Problem.create_type()

    create table(:auto_tracings) do
      add :current_step, Step.type()
      add :last_completed_step, Step.type()
      add :problems, {:array, Problem.type()}, default: []
      add :solved_problems, {:array, Problem.type()}, default: []
      add :unsolved_problems, :boolean, default: false
      add :covid_app, :boolean
      add :employed, :boolean
      add :occupations, {:array, :map}
      add :transmission, :map
      add :case_uuid, references(:cases, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    execute(
      """
      CREATE TRIGGER
        auto_tracing_versioning_insert
        AFTER INSERT ON auto_tracings
        FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
      """,
      """
      DROP TRIGGER auto_tracing_versioning_insert ON auto_tracings;
      """
    )

    execute(
      """
      CREATE TRIGGER
        auto_tracing_versioning_update
        AFTER UPDATE ON auto_tracings
        FOR EACH ROW EXECUTE PROCEDURE versioning_update();
      """,
      """
      DROP TRIGGER auto_tracing_versioning_update ON auto_tracings;
      """
    )

    execute(
      """
      CREATE TRIGGER
        auto_tracing_versioning_delete
        AFTER DELETE ON auto_tracings
        FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
      """,
      """
      DROP TRIGGER auto_tracing_versioning_delete ON auto_tracings;
      """
    )
  end
end
