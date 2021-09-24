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

  alias Hygeia.OrganisationContext.Affiliation

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: atom) :: String.t()
  def translate(:employee), do: pgettext("Affiliation Kind", "Employee")
  def translate(:scholar), do: pgettext("Affiliation Kind", "Scholar")
  def translate(:member), do: pgettext("Affiliation Kind", "Member")
  def translate(:other), do: pgettext("Affiliation Kind", "Other")

  @spec affilation_kind_name(affiliation :: Affiliation.t()) :: String.t() | nil
  def affilation_kind_name(%Affiliation{kind: nil}), do: nil

  def affilation_kind_name(%Affiliation{kind: :other, kind_other: kind_other}),
    do: "#{translate(:other)} / #{kind_other}"

  def affilation_kind_name(%Affiliation{kind: kind}), do: translate(kind)
end
