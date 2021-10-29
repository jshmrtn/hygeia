# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CaseRelatedOrganisations do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:case_related_organisations, primary_key: false) do
      add :case_uuid, references(:cases, on_delete: :nothing), null: false
      add :organisation_uuid, references(:organisations, on_delete: :nothing), null: false
    end
  end
end
