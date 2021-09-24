defmodule Hygeia.OrganisationContext.Organisation.Type do
  @moduledoc """
  Model for organisation types.
  """

  use EctoEnum,
    type: :type,
    enums: [
      :club,
      :school,
      :healthcare,
      :corporation,
      :other
    ]

  import HygeiaGettext

  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Organisation.SchoolType

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:club), do: pgettext("Organisation Type", "Club")
  def translate(:school), do: pgettext("Organisation Type", "School")
  def translate(:healthcare), do: pgettext("Organisation Type", "Healthcare")

  def translate(:corporation),
    do: pgettext("Organisation Type", "Corporation")

  def translate(:other), do: pgettext("Organisation Type", "Other")

  @spec organisation_type_name(organisation :: Organisation.t()) :: String.t() | nil
  def organisation_type_name(organisation)
  def organisation_type_name(%Organisation{type: nil}), do: nil

  def organisation_type_name(%Organisation{type: :school, school_type: nil}),
    do: translate(:school)

  def organisation_type_name(%Organisation{type: :school, school_type: school_type}),
    do: "#{translate(:school)}: #{SchoolType.translate(school_type)}"

  def organisation_type_name(%Organisation{type: type}), do: translate(type)

  def organisation_type_name(%Organisation{type: :other, type_other: other}),
    do: "#{translate(:other)}: #{other}"
end
