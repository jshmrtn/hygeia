# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.VersioningOriginatorIdNullable do
  @moduledoc false

  use Hygeia, :migration

  def change do
    drop constraint(:versions, :versions_originator_id_fkey)

    alter table(:versions, primary_key: false) do
      modify :originator_id, references(:users, on_delete: :nilify_all), null: true
    end

    drop constraint(:cases, :cases_tracer_uuid_fkey)
    drop constraint(:cases, :cases_supervisor_uuid_fkey)

    alter table(:cases, primary_key: false) do
      modify :tracer_uuid, references(:users, on_delete: :nilify_all), null: true
      modify :supervisor_uuid, references(:users, on_delete: :nilify_all), null: true
    end
  end
end
