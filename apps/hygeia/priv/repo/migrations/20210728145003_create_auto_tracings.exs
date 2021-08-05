# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Step

  def up do
    Step.create_type()

    create table(:auto_tracings) do
      add :current_step, Step.type()
      add :last_completed_step, Step.type()
      add :covid_app, :boolean
      add :employer, :map
      add :transmission, :map
      add :case_uuid, references(:cases, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    execute("""
    CREATE TRIGGER
      auto_tracing_versioning_insert
      AFTER INSERT ON auto_tracings
      FOR EACH ROW EXECUTE PROCEDURE versioning_insert();
    """)

    execute("""
    CREATE TRIGGER
      auto_tracing_versioning_update
      AFTER UPDATE ON auto_tracings
      FOR EACH ROW EXECUTE PROCEDURE versioning_update();
    """)

    execute("""
    CREATE TRIGGER
      auto_tracing_versioning_delete
      AFTER DELETE ON auto_tracings
      FOR EACH ROW EXECUTE PROCEDURE versioning_delete();
    """)
  end
end
