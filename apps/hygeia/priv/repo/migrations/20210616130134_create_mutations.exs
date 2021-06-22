# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateMutations do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:mutations) do
      add :name, :string
      add :ism_code, :integer

      timestamps()
    end

    create unique_index(:mutations, [:ism_code])

    alter table(:tests) do
      add :mutation_uuid, references(:mutations, on_delete: :nilify_all)
    end
  end
end
