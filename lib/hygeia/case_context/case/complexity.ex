defmodule Hygeia.CaseContext.Case.Complexity do
  @moduledoc "Case Complexity"

  use EctoEnum,
    type: :case_complexity,
    enums: [
      :low,
      :medium,
      :high,
      :extreme
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(end_reason)
  def translate(:low), do: pgettext("Case Complexity", "Low")
  def translate(:medium), do: pgettext("Case Complexity", "Medium")
  def translate(:high), do: pgettext("Case Complexity", "High")
  def translate(:extreme), do: pgettext("Case Complexity", "Extreme")
end
