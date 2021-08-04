# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Step

  def change do
    Step.create_type()

    create table(:auto_tracings) do
      add :current_step, Step.type()
      add :last_completed_step, Step.type()
      add :closed, :boolean
      add :employer, :map
      add :transmission, :map
      add :case_uuid, references(:cases, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
  end
end
