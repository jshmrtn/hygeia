# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule Hygeia.Repo.Migrations.AddAllEnums do
  @moduledoc false

  use Hygeia, :migration

  def change do
    Hygeia.CaseContext.Case.Clinical.TestReason.create_type()
    Hygeia.CaseContext.Case.Clinical.Symptom.create_type()
    Hygeia.CaseContext.Person.ContactMethod.Type.create_type()
    Hygeia.CaseContext.Case.Monitoring.IsolationLocation.create_type()
    Hygeia.CaseContext.Case.Phase.Index.EndReason.create_type()
    Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason.create_type()
    Hygeia.CaseContext.Case.Phase.PossibleIndex.Type.create_type()
    Hygeia.CaseContext.ExternalReference.Type.create_type()
    Hygeia.CaseContext.Test.Kind.create_type()
    Hygeia.CaseContext.Test.Result.create_type()
  end
end
