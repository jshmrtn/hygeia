# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.CreatePrematureReleaseDisabledReason do
  @moduledoc false

  use Hygeia, :migration

  alias Hygeia.CaseContext.PrematureRelease.DisabledReason

  def change do
    DisabledReason.create_type()
  end
end
