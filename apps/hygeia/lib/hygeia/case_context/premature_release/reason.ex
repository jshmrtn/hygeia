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

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(event :: t) :: String.t()
  def translate(:negative_test), do: pgettext("Premature Release Reason", "Negative Test")
  def translate(:immune), do: pgettext("Premature Release Reason", "Immune")
  def translate(:vaccinated), do: pgettext("Premature Release Reason", "Vaccinated")
end
