defmodule Hygeia.Repo.Migrations.CreatePeople do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Person.Sex

  def change do
    Sex.create_type()

    create table(:people) do
      add :human_readable_id, :string
      add :external_references, {:array, :map}
      add :first_name, :string
      add :last_name, :string
      add :sex, Sex.type()
      add :birth_date, :date
      add :contact_methods, {:array, :map}
      add :address, :map
      add :employers, {:array, :map}
      add :profession_uuid, references(:professions, on_delete: :nilify_all, type: :binary_id)
      add :tenant_uuid, references(:tenants, on_delete: :nilify_all, type: :binary_id)

      timestamps()
    end

    create index(:people, [:profession_uuid])
    create index(:people, [:tenant_uuid])
    create index(:people, [:external_references], using: :gin)
    create index(:people, [:contact_methods], using: :gin)
  end
end
