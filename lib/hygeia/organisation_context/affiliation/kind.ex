defmodule Hygeia.OrganisationContext.Affiliation.Kind do
  @moduledoc "Affiliation Kind"

  use EctoEnum,
    type: :affiliation_kind,
    enums: [
      :employee,
      :scholar,
      :member,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: atom) :: String.t()
  def translate(:employee), do: pgettext("Affiliation Kind", "Employee")
  def translate(:scholar), do: pgettext("Affiliation Kind", "Scholar")
  def translate(:member), do: pgettext("Affiliation Kind", "Member")
  def translate(:other), do: pgettext("Affiliation Kind", "Other")
end
