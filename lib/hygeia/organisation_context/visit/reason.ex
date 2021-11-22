defmodule Hygeia.OrganisationContext.Visit.Reason do
  @moduledoc "Defines visit reason types."

  use EctoEnum,
    type: :visit_reason,
    enums: [
      :student,
      :professor,
      :employee,
      :visitor,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:student), do: pgettext("Visit reason", "Student")
  def translate(:professor), do: pgettext("Visit reason", "Professor")
  def translate(:employee), do: pgettext("Visit reason", "Employee")
  def translate(:visitor), do: pgettext("Visit reason", "Visitor")
  def translate(:other), do: pgettext("Visit reason", "Other")
end
