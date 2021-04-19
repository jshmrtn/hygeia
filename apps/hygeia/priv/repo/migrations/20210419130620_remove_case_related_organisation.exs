# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.RemoveCaseRelatedOrganisation do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop table(:case_related_organisations)
  end
end
