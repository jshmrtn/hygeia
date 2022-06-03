# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AlterEmploymentStatusInAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.EmploymentStatus

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    alter table(:auto_tracings) do
      add :employed_tmp, :boolean
    end

    execute(
      """
      UPDATE auto_tracings
      SET employed_tmp = employed;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :employed
    end

    EmploymentStatus.create_type()

    alter table(:auto_tracings) do
      add :employed, EmploymentStatus.type()
    end

    execute(
      """
      UPDATE auto_tracings at
      SET employed =
        CASE
          WHEN at.employed_tmp IS TRUE THEN 'yes'::employment_status
          WHEN at.employed_tmp IS FALSE THEN 'no'::employment_status
          ELSE NULL
        END;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :employed_tmp
    end
  end

  def down do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    alter table(:auto_tracings) do
      add :employed_tmp, EmploymentStatus.type()
    end

    execute(
      """
      UPDATE auto_tracings
      SET employed_tmp = employed;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :employed
    end

    alter table(:auto_tracings) do
      add :employed, :boolean
    end

    execute(
      """
      UPDATE auto_tracings at
      SET employed =
        CASE
          WHEN at.employed_tmp = 'yes' THEN TRUE
          WHEN at.employed_tmp = 'no' THEN FALSE
          ELSE NULL
        END;
      """,
      &noop/0
    )

    alter table(:auto_tracings) do
      remove :employed_tmp
    end

    EmploymentStatus.drop_type()
  end
end
