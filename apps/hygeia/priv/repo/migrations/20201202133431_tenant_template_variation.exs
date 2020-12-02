# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TenantTemplateVariation do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.TenantContext.Tenant.TemplateVariation

  def change do
    TemplateVariation.create_type()

    alter table(:tenants) do
      add :template_variation, TemplateVariation.type(), null: true
    end
  end
end
