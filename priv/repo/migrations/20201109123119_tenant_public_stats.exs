# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantPublicStats do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :public_statistics, :boolean, default: false, null: false
    end
  end
end
