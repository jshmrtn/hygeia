defmodule Hygeia.CaseContext.Test.Result do
  @moduledoc "Test Result"

  use EctoEnum,
    type: :test_result,
    enums: [
      :positive,
      :inconclusive,
      :negative
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:positive), do: pgettext("Test Result", "Positive")
  def translate(:negative), do: pgettext("Test Result", "Negative")
  def translate(:inconclusive), do: pgettext("Test Result", "Inconclusive")
end
