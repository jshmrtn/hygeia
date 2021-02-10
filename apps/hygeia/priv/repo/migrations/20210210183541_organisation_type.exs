# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.OrganisationType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.OrganisationContext.Organisation

  def change do
    Organisation.Type.create_type()

    alter table(:organisations) do
      add :type, Organisation.Type.type()
      add :type_other, :string
    end
  end
end
