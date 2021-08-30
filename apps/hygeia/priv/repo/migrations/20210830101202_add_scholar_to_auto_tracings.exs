defmodule Hygeia.Repo.Migrations.AddScholarToAutoTracings do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table("auto_tracings") do
      add :scholar, :boolean
    end
  end
end
