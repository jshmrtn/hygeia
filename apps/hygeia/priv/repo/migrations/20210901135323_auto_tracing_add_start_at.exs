# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingAddStartAt do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:auto_tracings) do
      add :started_at, :utc_datetime_usec
    end

    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    UPDATE auto_tracings
    SET started_at = inserted_at
    """)

    alter table(:auto_tracings) do
      modify :started_at, :utc_datetime_usec, null: false
    end
  end
end
