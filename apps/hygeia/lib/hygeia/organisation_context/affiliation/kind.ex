defmodule Hygeia.OrganisationContext.Affiliation.Kind do
  @moduledoc false

  use EctoEnum,
    type: :affiliation_kind,
    enums: [
      :employee,
      :scholar,
      :member,
      :other
    ]

  import HygeiaGettext

  @spec translate_affiliation_kind(type :: atom) :: String.t()
  def translate_affiliation_kind(:employee), do: pgettext("Affiliation Kind", "Employee")
  def translate_affiliation_kind(:scholar), do: pgettext("Affiliation Kind", "Scholar")
  def translate_affiliation_kind(:member), do: pgettext("Affiliation Kind", "Member")
  def translate_affiliation_kind(:other), do: pgettext("Affiliation Kind", "Other")
end
