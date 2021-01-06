# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.GrantNewRoles do
  @moduledoc false

  use Hygeia, :migration

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      grant_role
      ADD VALUE IF NOT EXISTS 'data_exporter';
    """)

    execute("""
    ALTER TYPE
      grant_role
      ADD VALUE IF NOT EXISTS 'super_user';
    """)
  end
end
