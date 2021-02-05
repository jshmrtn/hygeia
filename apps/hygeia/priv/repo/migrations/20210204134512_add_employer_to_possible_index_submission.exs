# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddEmployerToPossibleIndexSubmission do
  @moduledoc false

  use Hygeia, :migration

  def up do
    alter table(:possible_index_submissions) do
      add :employer, :string
    end
  end
end
