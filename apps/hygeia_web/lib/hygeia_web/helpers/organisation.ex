defmodule HygeiaWeb.Helpers.Organisation do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Affiliation.Kind
  alias Hygeia.OrganisationContext.Organisation

  @spec affiliation_kinds :: [{String.t(), Kind.t()}]
  def affiliation_kinds,
    do:
      Enum.map(
        Kind.__enum_map__(),
        &{Kind.translate_affiliation_kind(&1), &1}
      )

  @spec affilation_kind(affiliation :: Affiliation.t()) :: String.t()
  def affilation_kind(%Affiliation{kind: :other, kind_other: kind_other}),
    do: "#{Kind.translate_affiliation_kind(:other)} / #{kind_other}"

  def affilation_kind(%Affiliation{kind: kind}), do: Kind.translate_affiliation_kind(kind)

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
