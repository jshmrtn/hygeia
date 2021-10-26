defmodule Hygeia.OrganisationContext.Organisation.SchoolType do
  @moduledoc """
  Model for organisation school types.
  """

  use EctoEnum,
    type: :school_type,
    enums: [
      :preschool,
      :primary_school,
      :secondary_school,
      :cantonal_school_or_other_middle_school,
      :professional_school,
      :university_or_college,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:preschool), do: pgettext("School Type", "Preschool")

  def translate(:primary_school),
    do: pgettext("School Type", "Primary school")

  def translate(:secondary_school),
    do: pgettext("School Type", "Secondary school")

  def translate(:cantonal_school_or_other_middle_school),
    do: pgettext("School Type", "Cantonal school or other middle school")

  def translate(:professional_school),
    do: pgettext("School Type", "Professional school")

  def translate(:university_or_college),
    do: pgettext("School Type", "University or college")

  def translate(:other), do: pgettext("School Type", "Other")
end
