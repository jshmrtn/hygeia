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

    execute(
      """
      UPDATE cases update_case
      SET phases = replace_case.new_phases
      FROM (
        SELECT
          cases.uuid AS case_uuid,
          ARRAY_AGG(
            JSONB_BUILD_OBJECT('premature_release_permission', 'true', 'premature_release_disabled_reason', NULL, 'premature_release_disabled_reason_other', NULL) ||
            phase
          ) AS new_phases
          FROM cases
          CROSS JOIN
          UNNEST(cases.phases)
          AS phase
        GROUP BY cases.uuid
      ) replace_case
      WHERE replace_case.case_uuid = update_case.uuid;
      """,
      """
      UPDATE cases update_case
      SET phases = replace_case.new_phases
      FROM (
        SELECT
          cases.uuid AS case_uuid,
          ARRAY_AGG(
            phase - 'premature_release_permission' - 'premature_release_disabled_reason' - 'premature_release_disabled_reason_other'
          ) AS new_phases
          FROM cases
          CROSS JOIN
          UNNEST(cases.phases)
          AS phase
        GROUP BY cases.uuid
      ) replace_case
      WHERE replace_case.case_uuid = update_case.uuid;
      """
    )

    execute(&noop/0, fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)
  end
end
