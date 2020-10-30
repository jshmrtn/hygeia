# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateUser do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:users) do
      add :email, :string
      add :display_name, :string
      add :iam_sub, :string

      timestamps()
    end

    create unique_index(:users, :iam_sub)
  end
end
