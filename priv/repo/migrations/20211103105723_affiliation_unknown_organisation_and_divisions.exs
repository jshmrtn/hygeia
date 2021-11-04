# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AffiliationUnknownOrganisationAndDivisions do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute(fn ->
      :ok = run_authentication(repo(), origin: :migration, originator: :noone)
    end)

    alter table(:affiliations) do
      add :unknown_organisation, :map, default: nil
      add :unknown_division, :map, default: nil
    end

    drop constraint(:affiliations, :comment_required)

    create constraint(:affiliations, :organisation_info_required,
             check:
               "organisation_uuid IS NOT NULL OR unknown_organisation IS NOT NULL OR comment IS NOT NULL"
           )

    execute """
    INSERT
      INTO affiliations
      (uuid, kind, kind_other, person_uuid, inserted_at, updated_at, related_school_visit_uuid, unknown_organisation)
      SELECT
          (occupation->>'uuid')::uuid,
          (occupation->>'kind')::affiliation_kind,
          (occupation->>'kind_other'),
          cases.person_uuid,
          NOW(),
          NOW(),
          (occupation->>'related_school_visit_uuid')::uuid,
          (occupation->'unknown_organisation')
      FROM auto_tracings
      JOIN cases ON auto_tracings.case_uuid = cases.uuid
      CROSS JOIN UNNEST(auto_tracings.occupations) AS occupation
    """

    alter table(:auto_tracings) do
      remove :occupations
    end
  end
end
