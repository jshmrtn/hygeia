# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.TransmissionType do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type

  def change do
    alter table(:transmissions) do
      add :type, Type.type(), null: false, default: "contact_person"
    end
  end
end
