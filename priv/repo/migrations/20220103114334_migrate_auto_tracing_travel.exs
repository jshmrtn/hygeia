# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.MigrateAutoTracingTravel do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    rename table(:auto_tracings), :has_travelled, to: :has_travelled_in_risk_country

    alter table(:auto_tracings) do
      add :travels, {:array, :map}
    end

    execute(
      """
      UPDATE auto_tracings at
      SET travels =
        CASE
          WHEN at.travel IS NULL
          THEN ARRAY[]::jsonb[]
          ELSE ARRAY[
              at.travel - 'return_date' ||
              jsonb_build_object('last_departure_date', at.travel->'return_date')
          ]::jsonb[]
        END;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :travel
    end
  end

  def down do
    execute(
      fn ->
        :ok = run_authentication(repo(), origin: :migration, originator: :noone)
      end,
      &noop/0
    )

    rename table(:auto_tracings), :has_travelled_in_risk_country, to: :has_travelled

    alter table(:auto_tracings) do
      add :travel, :map
    end

    execute(
      """
      UPDATE auto_tracings at
      SET travel =
        CASE
          WHEN at.travels[1]::jsonb IS NULL
          THEN 'NULL
          ELSE
            at.travels[1] - 'last_departure_date' ||
            jsonb_build_object('return_date', at.travels[1]->'last_departure_date')
        END;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :travels
    end
  end
end
