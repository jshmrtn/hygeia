# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantCaseManagementSwitch do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :case_management_enabled, :boolean, default: false
    end

    execute(
      """
      UPDATE tenants
      SET case_management_enabled = CASE
        WHEN name = 'Hygeia - Covid19 Tracing' THEN false
        ELSE true
      END
      """,
      &noop/0
    )
  end

  defp noop, do: nil
end
