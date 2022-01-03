defmodule Hygeia.CaseContext.PrematureRelease.Reason do
  @moduledoc """
  Premature Release Reason
  """

  use EctoEnum,
    type: :premature_release_reason,
    enums: [
      :negative_test,
      :immune,
      :vaccinated
    ]

  import HygeiaGettext

  @deprecated_options [:negative_test]

  @spec map :: [{String.t(), t}]
  def map, do: __enum_map__() |> Kernel.--(@deprecated_options) |> Enum.map(&{translate(&1), &1})

  @spec translate(event :: t) :: String.t()
  def translate(:negative_test), do: pgettext("Premature Release Reason", "Negative Test")
  def translate(:immune), do: pgettext("Premature Release Reason", "Immune")
  def translate(:vaccinated), do: pgettext("Premature Release Reason", "Vaccinated")

  @spec deprecated_options :: [t]
  def deprecated_options, do: @deprecated_options
end
