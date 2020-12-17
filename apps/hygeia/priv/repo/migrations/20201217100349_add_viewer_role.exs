# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddViewerRole do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      grant_role
      ADD VALUE IF NOT EXISTS 'viewer';
    """)
  end
end
