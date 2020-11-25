# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddTenantOverrideUrl do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :override_url, :string
    end
  end
end
