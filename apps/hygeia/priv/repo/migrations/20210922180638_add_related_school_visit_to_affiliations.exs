# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddRelatedSchoolVisitToAffiliations do
  use Ecto.Migration

  def change do
    alter table(:affiliations) do
      add :related_school_visit_uuid, :binary_id
    end
  end
end
