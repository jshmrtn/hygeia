# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddAnonymizationJobToVersioningType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.VersionContext.Version

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Version.Origin.type()}
      ADD VALUE IF NOT EXISTS 'anonymization_job';
    """)
  end
end
