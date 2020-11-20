# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddOutgoingSmsConfiguration do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:tenants) do
      add :outgoing_sms_configuration, :map
    end
  end
end
