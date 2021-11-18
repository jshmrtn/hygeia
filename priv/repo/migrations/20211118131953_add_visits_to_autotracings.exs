# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddVisitsToAutotracings do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AutoTracingContext.AutoTracing.Step

  def up do
    execute("""
      ALTER TYPE
      #{Step.type()}
      ADD VALUE IF NOT EXISTS 'visits' AFTER 'contact_methods';
    """)

    execute("""
      ALTER TABLE affiliations
      RENAME COLUMN related_school_visit_uuid TO related_visit_uuid;
    """)
  end
end
