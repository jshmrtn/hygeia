# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddPinnedToNotes do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:notes) do
      add :pinned, :boolean, default: false
    end

    create index(:notes, [:case_uuid, :pinned])
  end
end
