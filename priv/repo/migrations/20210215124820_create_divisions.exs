# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateDivisions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:divisions) do
      add :title, :string, null: false
      add :description, :text, null: true
      add :organisation_uuid, references(:organisations, on_delete: :nothing), null: false
      add :shares_address, :boolean, default: true
      add :address, :map, default: nil

      timestamps()
    end

    create constraint(:divisions, :address_required,
             check: """
             CASE
              WHEN shares_address THEN address IS NULL
              ELSE address IS NOT NULL
             END
             """
           )

    create index(:divisions, [:organisation_uuid])

    alter table(:affiliations) do
      add :division_uuid, references(:divisions, on_delete: :nothing), null: true
    end

    create index(:affiliations, [:division_uuid])
  end
end
