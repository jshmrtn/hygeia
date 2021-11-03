# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddUnknownOrganisationAndDivisionToAffiliations do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:affiliations) do
      add :unknown_organisation, :map, default: nil
      add :unknown_division, :map, default: nil
    end

    drop constraint(:affiliations, :comment_required)

    create constraint(:affiliations, :organisation_info_required,
             check:
               "organisation_uuid IS NOT NULL OR unknown_organisation IS NOT NULL OR comment IS NOT NULL"
           )
  end
end
