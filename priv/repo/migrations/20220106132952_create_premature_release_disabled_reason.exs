# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePrematureReleaseDisabledReason do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.PrematureRelease.DisabledReason

  def change do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    DisabledReason.create_type()

    # TODO: Complete queries.
    execute(
      """
      UPDATE cases update_case
      SET phases = update_case.phases
      """,
      """
      UPDATE cases update_case
      SET phases = update_case.phases;
      """
    )

    execute(&noop/0, fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)
  end
end
