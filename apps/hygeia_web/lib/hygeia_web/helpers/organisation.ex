defmodule HygeiaWeb.Helpers.Organisation do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.OrganisationContext.Affiliation

  @spec affiliation_kinds :: [{String.t(), Affiliation.Kind.t()}]
  def affiliation_kinds,
    do:
      Enum.map(
        Affiliation.Kind.__enum_map__(),
        &{translate_affiliation_kind(&1), &1}
      )

  @spec translate_affiliation_kind(type :: Affiliation.Kind.t()) :: String.t()
  def translate_affiliation_kind(:employee), do: pgettext("Affiliation Kind", "Employee")
  def translate_affiliation_kind(:scholar), do: pgettext("Affiliation Kind", "Scholar")
  def translate_affiliation_kind(:member), do: pgettext("Affiliation Kind", "Member")
  def translate_affiliation_kind(:other), do: pgettext("Affiliation Kind", "Other")
end
