# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AlterEmploymentStatusInAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.EmploymentStatus

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    EmploymentStatus.create_type()

    execute("""
    ALTER
    table auto_tracings
    ALTER
      employed
      SET DATA TYPE #{EmploymentStatus.type()}
      USING CASE
      WHEN employed IS TRUE THEN 'yes'::employment_status
      WHEN employed IS FALSE THEN 'no'::employment_status
      ELSE NULL
    END;
    """)
  end

  def down do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    execute("""
    ALTER
    table auto_tracings
    ALTER
      employed
      SET DATA TYPE BOOL
      USING CASE
      WHEN employed = 'yes' THEN TRUE
      WHEN employed = 'no' THEN FALSE
      ELSE NULL
    END;
    """)

    EmploymentStatus.drop_type()
  end
end
