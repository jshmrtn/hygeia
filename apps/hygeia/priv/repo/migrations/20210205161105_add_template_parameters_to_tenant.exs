# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.AddTemplateParametersToTenant do
  @moduledoc false

  use Hygeia, :migration

  def up do
    alter table(:tenants) do
      add :template_parameters, :map
    end

    execute("""
    UPDATE tenants
    SET template_parameters = JSONB_BUILD_OBJECT(
      'uuid', MD5(RANDOM()::text || CLOCK_TIMESTAMP()::text)::uuid,
      'message_sender', 'Contact Tracing St.Gallen, Appenzell Innerrhoden, Appenzell Ausserrhoden Kantonaler Führungsstab: KFS'
    )
    WHERE name IN ('Kanton Sankt Gallen', 'Kanton Appenzell Ausserrhoden', 'Kanton Appenzell Innerrhoden')
    """)
  end
end
