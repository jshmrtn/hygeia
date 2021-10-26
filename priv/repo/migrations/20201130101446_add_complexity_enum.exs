# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Hygeia.Repo.Migrations.AddComplexityEnum do
  @moduledoc false

  use Hygeia, :migration

  def change do
    Hygeia.CaseContext.Case.Complexity.create_type()
  end
end
