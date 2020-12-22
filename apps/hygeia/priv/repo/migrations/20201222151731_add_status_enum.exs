# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddStatusEnum do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Case.Status

  def up do
    Status.create_type()

    rename table(:cases), :status, to: :status_old

    alter table(:cases) do
      add :status, Status.type(), null: true
    end

    execute("""
      UPDATE cases
      SET status = status_old::case_status;
    """)

    alter table(:cases) do
      modify :status, Status.type(), null: false
      remove :status_old
    end
  end
end
