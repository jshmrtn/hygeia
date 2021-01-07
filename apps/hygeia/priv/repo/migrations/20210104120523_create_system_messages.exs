# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateSystemMessages do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:system_messages) do
      add :text, :text
      add :start_date, :date
      add :end_date, :date
      add :roles, {:array, :grant_role}, default: []

      timestamps()
    end

    create table(:system_message_tenants, primary_key: false) do
      add :system_message_uuid, references(:system_messages, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :tenant_uuid, references(:tenants, on_delete: :delete_all),
        null: false,
        primary_key: true
    end
  end
end
