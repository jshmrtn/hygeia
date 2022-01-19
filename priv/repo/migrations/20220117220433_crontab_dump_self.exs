# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CrontabDumpSelf do
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
      UPDATE
        tenants
        SET
          sedex_export_configuration = sedex_export_configuration || JSONB_BUILD_OBJECT(
            'schedule',
            JSONB_BUILD_OBJECT(
              'extended',
              FALSE,
              'expression',
              sedex_export_configuration->'schedule'
            )
          )
        WHERE sedex_export_enabled
      """,
      """
      UPDATE
        tenants
        SET
          sedex_export_configuration = sedex_export_configuration || JSONB_BUILD_OBJECT(
            'schedule',
            sedex_export_configuration->'schedule'->'expression'
          )
        WHERE sedex_export_enabled
      """
    )

    execute(&noop/0, fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)
  end
end
