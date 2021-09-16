# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddOrganisationSchoolType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Organisation

  def change do
    Organisation.SchoolType.create_type()

    alter table(:organisations) do
      add :school_type, Organisation.SchoolType.type()
    end
  end
end
