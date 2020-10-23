defmodule Hygeia.Repo.Migrations.FlatUserRoles do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.UserContext.User.Role

  def change do
    Role.create_type()

    alter table(:users) do
      add :roles, {:array, :user_role}, default: []
    end
  end
end
