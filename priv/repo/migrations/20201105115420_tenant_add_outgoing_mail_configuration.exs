# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantAddOutgoingMailConfiguration do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :outgoing_mail_configuration, :map
    end
  end
end
