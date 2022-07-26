# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveOrganisationPositionFeature do
  @moduledoc false

  use Hygeia, :migration

  def up do
    execute("""
    DELETE FROM versions
    WHERE item_table = 'positions'
    """)

    drop table(:positions)
  end
end
