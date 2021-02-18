defmodule HygeiaWeb.Helpers.Organisation do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation

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

  @spec affilation_kind(affiliation :: Affiliation.t()) :: String.t()
  def affilation_kind(%Affiliation{kind: :other, kind_other: kind_other}),
    do: "#{translate_affiliation_kind(:other)} / #{kind_other}"

  def affilation_kind(%Affiliation{kind: kind}), do: translate_affiliation_kind(kind)

  @spec organisation_types :: [{String.t(), Organisation.Type.t()}]
  def organisation_types,
    do:
      Enum.map(
        Organisation.Type.__enum_map__(),
        &{organisation_type_translation(&1), &1}
      )

  @spec organisation_type_name(organisation :: Organisation.t()) :: String.t() | nil
  def organisation_type_name(organisation)
  def organisation_type_name(%Organisation{type: nil}), do: nil
  def organisation_type_name(%Organisation{type: type}), do: organisation_type_translation(type)

  def organisation_type_name(%Organisation{type: :other, type_other: other}),
    do: "#{organisation_type_translation(:other)}: #{other}"

  @spec organisation_type_translation(type :: Organisation.Type.t()) :: String.t()
  def organisation_type_translation(:club), do: pgettext("Organisation Type", "Club")
  def organisation_type_translation(:school), do: pgettext("Organisation Type", "School")
  def organisation_type_translation(:healthcare), do: pgettext("Organisation Type", "Healthcare")

  def organisation_type_translation(:corporation),
    do: pgettext("Organisation Type", "Corporation")

  def organisation_type_translation(:other), do: pgettext("Organisation Type", "Other")
end
