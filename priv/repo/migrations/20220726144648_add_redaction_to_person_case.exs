# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddRedactionToPersonCase do
  @moduledoc false

  use Hygeia, :migration

  def change do
    alter table(:people) do
      add :redacted, :boolean, default: false
      add :redaction_date, :date
      add :reidentification_date, :date
    end

    alter table(:cases) do
      add :redacted, :boolean, default: false
      add :redaction_date, :date
      add :reidentification_date, :date
    end
  end
end
