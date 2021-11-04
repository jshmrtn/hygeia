# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.DetectUnchangedCasesEnum do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.VersionContext.Version.Origin

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Origin.type()}
      ADD VALUE IF NOT EXISTS 'detect_unchanged_cases_job';
    """)
  end
end
