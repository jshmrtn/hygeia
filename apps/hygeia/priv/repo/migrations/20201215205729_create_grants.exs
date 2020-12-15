# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateGrants do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.UserContext.Grant.Role

  def up do
    alter table(:users) do
      remove :roles
    end

    execute("""
    DROP TYPE user_role;
    """)

    Role.create_type()

    create table(:user_grants, primary_key: false) do
      add :user_uuid, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :tenant_uuid, references(:tenants, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :role, Role.type(), null: false, primary_key: true

      timestamps()
    end

    alter table(:tenants) do
      add :iam_domain, :string, null: true
      add :short_name, :string, null: true
    end

    create unique_index(:tenants, [:iam_domain])
    create unique_index(:tenants, [:short_name])
  end
end
