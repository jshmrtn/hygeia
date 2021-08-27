# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddImportFilename do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:imports) do
      add :filename, :string
    end
  end
end
