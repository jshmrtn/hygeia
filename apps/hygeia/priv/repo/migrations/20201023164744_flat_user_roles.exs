# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FlatUserRoles do
  @moduledoc false

  use Hygeia, :migration

  import EctoEnum

  defenum(Role, :user_role, ["tracer", "supervisor", "admin", "webmaster", "statistics_viewer"])

  def change do
    Role.create_type()

    alter table(:users) do
      add :roles, {:array, :user_role}, default: []
    end
  end
end
