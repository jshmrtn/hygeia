# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddUniversityToSchoolType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Organisation.SchoolType

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{SchoolType.type()}
      ADD VALUE IF NOT EXISTS 'university_or_college';
    """)
  end
end
