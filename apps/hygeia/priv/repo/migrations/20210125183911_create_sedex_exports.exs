# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateSedexExports do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.TenantContext.SedexExport.Status

  def change do
    Status.create_type()

    create table(:sedex_exports) do
      add :scheduling_date, :naive_datetime
      add :status, Status.type()
      add :tenant_uuid, references(:tenants, on_delete: :nothing)

      timestamps()
    end

    create index(:sedex_exports, [:tenant_uuid])
  end
end
