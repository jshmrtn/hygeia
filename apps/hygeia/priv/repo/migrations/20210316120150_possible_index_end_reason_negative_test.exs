# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.PossibleIndexEndReasonNegativeTest do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason

  def change do
    execute("""
    ALTER TYPE #{EndReason.type()}
      ADD VALUE IF NOT EXISTS 'negative_test'
    """)
  end
end
