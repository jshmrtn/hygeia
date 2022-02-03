# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveVaccinationFailureFromAutoTracingProblems do
  @moduledoc false

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
        SET problems = ARRAY_REMOVE(problems, 'vaccination_failure')
        WHERE 'vaccination_failure' = ANY(problems)
      """,
      &noop/0
    )

    execute(
      """
        UPDATE auto_tracings
        SET solved_problems = ARRAY_REMOVE(solved_problems, 'vaccination_failure')
        WHERE 'vaccination_failure' = ANY(solved_problems)
      """,
      &noop/0
    )
  end
end
