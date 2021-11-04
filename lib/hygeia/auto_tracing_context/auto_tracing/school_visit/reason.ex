defmodule Hygeia.AutoTracingContext.AutoTracing.SchoolVisit.Reason do
  @moduledoc "Defines visit reason types."

  use EctoEnum,
    type: :school_visit_reason,
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
  def translate(:student), do: pgettext("School visit reason", "Student")
  def translate(:professor), do: pgettext("School visit reason", "Professor")
  def translate(:employee), do: pgettext("School visit reason", "Employee")
  def translate(:visitor), do: pgettext("School visit reason", "Visitor")
  def translate(:other), do: pgettext("School visit reason", "Other")
end
