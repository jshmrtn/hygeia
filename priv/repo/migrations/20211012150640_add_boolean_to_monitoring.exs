# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddBooleanToMonitoring do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    UPDATE cases
    SET
      monitoring = monitoring || jsonb_build_object('different_location',
        CASE
          WHEN monitoring->'address'->>'address' IS NOT NULL THEN true
          ELSE false
        END)
    """)

    execute("""
    UPDATE cases
    SET
      monitoring = monitoring || jsonb_build_object('address',
        CASE
          WHEN monitoring->'address'->>'address' IS NULL THEN NULL
          ELSE monitoring->'address'
        END)
    """)
  end
end
