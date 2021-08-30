# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AutoTracingContactPersonsStep do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Step

  @disable_ddl_transaction true

  def up do
    execute("""
    ALTER TYPE
      #{Step.type()}
      ADD VALUE IF NOT EXISTS 'contact_persons';
    """)
  end
end
