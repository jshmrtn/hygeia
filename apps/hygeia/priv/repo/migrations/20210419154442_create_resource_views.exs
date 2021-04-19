# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreateResourceViews do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.AuditContext.ResourceView

  def change do
    ResourceView.Action.create_type()
    ResourceView.AuthType.create_type()

    create table(:resource_views, primary_key: false) do
      add :request_id, :bigint, null: false
      add :auth_type, ResourceView.AuthType.type(), null: false
      add :auth_subject, :uuid, null: true
      add :time, :utc_datetime_usec, null: false
      add :ip_address, :inet, null: true
      add :uri, :text, null: true
      add :action, ResourceView.Action.type(), null: false
      add :resource_table, :string, null: false
      add :resource_pk, :map, null: false
    end

    create unique_index(:resource_views, [
             :request_id,
             :action,
             :resource_table,
             :resource_pk
           ])
  end
end
