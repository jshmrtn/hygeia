defmodule Hygeia.Repo.Migrations.FulltextSearchIndex do
  @moduledoc false

  use Hygeia, :migration

  def change do
    execute """
    CREATE EXTENSION pg_trgm
    """
  end
end
