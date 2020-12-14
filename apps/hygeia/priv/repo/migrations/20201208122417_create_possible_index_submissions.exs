# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePossibleIndexSubmissions do
  @moduledoc false

  use Hygeia, :migration

  def change do
    create table(:possible_index_submissions) do
      add :first_name, :string
      add :last_name, :string

      add :email, :string
      add :mobile, :string
      add :landline, :string
      add :sex, :string
      add :birth_date, :date

      add :address, :map
      add :infection_place, :map

      add :transmission_date, :date

      add :case_uuid, references(:cases, on_delete: :delete_all)

      timestamps()
    end
  end
end
