# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.EmailContextUser do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    alter table(:emails) do
      modify :case_uuid, references(:cases, on_delete: :delete_all),
        from: references(:cases, on_delete: :delete_all),
        null: true

      add :user_uuid, references(:users, on_delete: :delete_all), null: true

      add :tenant_uuid, references(:tenants, on_delete: :delete_all), null: true
    end

    create constraint(:emails, :context_must_be_provided,
             check: "case_uuid IS NOT NULL OR user_uuid IS NOT NULL"
           )

    execute("""
    UPDATE emails
      SET tenant_uuid = cases.tenant_uuid
      FROM cases
      WHERE cases.uuid = emails.case_uuid
    """)

    alter table(:emails) do
      modify :tenant_uuid, references(:tenants, on_delete: :delete_all),
        from: references(:tenants, on_delete: :delete_all),
        null: false
    end
  end
end
