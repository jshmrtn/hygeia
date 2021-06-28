# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.DeleteCascadeRest do
  @moduledoc false

  use Hygeia, :migration

  def up do
    drop constraint(:cases, :cases_person_uuid_fkey)

    execute("""
    ALTER TABLE ONLY cases
      ADD CONSTRAINT cases_person_uuid_fkey
      FOREIGN KEY (person_uuid)
      REFERENCES people(uuid)
      ON DELETE CASCADE;
    """)
  end
end
