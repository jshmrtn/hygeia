# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddResidentToAffiliationKind do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Affiliation.Kind

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Kind.type()}
      ADD VALUE IF NOT EXISTS 'resident';
    """)
  end
end
