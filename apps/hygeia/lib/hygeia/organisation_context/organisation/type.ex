defmodule Hygeia.OrganisationContext.Organisation.Type do
  @moduledoc """
  Model for organisation types.
  """

  use EctoEnum,
    type: :organisation_type,
    enums: [
      :club,
      :school,
      :healthcare,
      :corporation,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:club), do: pgettext("Organisation Type", "Club")
  def translate(:school), do: pgettext("Organisation Type", "School")
  def translate(:healthcare), do: pgettext("Organisation Type", "Healthcare")

  def translate(:corporation),
    do: pgettext("Organisation Type", "Corporation")

  def translate(:other), do: pgettext("Organisation Type", "Other")
end
