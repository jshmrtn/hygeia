# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingTravelMigration do
  use Hygeia, :migration

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    execute(
      """
        UPDATE auto_tracings
          SET current_step = 'travel'
          WHERE current_step = 'flights';
      """,
      """
      UPDATE auto_tracings
        SET current_step = 'flights'
        WHERE current_step = 'travel';
      """
    )

    execute(
      """
        UPDATE auto_tracings
          SET last_completed_step = 'travel'
          WHERE last_completed_step = 'flights';
      """,
      """
      UPDATE auto_tracings
        SET last_completed_step = 'flights'
        WHERE last_completed_step = 'travel';
      """
    )

    execute(
      &noop/0,
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end
    )
  end
end
