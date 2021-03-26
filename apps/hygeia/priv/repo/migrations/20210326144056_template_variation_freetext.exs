# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TemplateVariationFreetext do
  @moduledoc false

  use Hygeia, :migration

  import EctoEnum

  defenum(TemplateVariation, :template_variation, [:sg, :ar, :ai])

  def up do
    alter table(:tenants) do
      modify :template_variation, :string, from: TemplateVariation.type(), null: true
    end

    TemplateVariation.drop_type()
  end

  def down do
    TemplateVariation.create_type()

    alter table(:tenants) do
      modify :template_variation, TemplateVariation.type(), from: :string, null: true
    end
  end
end
