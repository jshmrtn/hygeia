# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FulltextSearchIndex do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute """
    CREATE EXTENSION IF NOT EXISTS pg_trgm
    """
  end
end
