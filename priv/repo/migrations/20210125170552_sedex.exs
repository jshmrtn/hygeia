# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.Sedex do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :sedex_export_enabled, :boolean, default: false, null: false
      add :sedex_export_configuration, :map, null: true
    end

    create constraint(:tenants, :sedex_export_must_be_provided,
             check:
               "(sedex_export_enabled = true AND sedex_export_configuration IS NOT NULL) OR (sedex_export_enabled = false AND sedex_export_configuration IS NULL)"
           )
  end
end
