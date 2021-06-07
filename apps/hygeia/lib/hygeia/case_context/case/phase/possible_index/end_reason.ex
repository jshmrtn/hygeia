defmodule Hygeia.CaseContext.Case.Phase.PossibleIndex.EndReason do
  @moduledoc "Possible Index Phase End Reason"

  use EctoEnum,
    type: :case_phase_possible_index_end_reason,
    enums: [
      :asymptomatic,
      :converted_to_index,
      :no_follow_up,
      :negative_test,
      :immune,
      :vaccinated,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(end_reason)
  def translate(:asymptomatic), do: pgettext("Possible Index End Reason", "Asymptomatic")

  def translate(:converted_to_index),
    do: pgettext("Possible Index End Reason", "Converted to Index")

  def translate(:no_follow_up), do: pgettext("Possible Index End Reason", "No Follow Up")
  def translate(:negative_test), do: pgettext("Possible Index End Reason", "Negative Test")
  def translate(:immune), do: pgettext("Possible Index End Reason", "Immune")
  def translate(:vaccinated), do: pgettext("Possible Index End Reason", "Vaccinated")
  def translate(:other), do: pgettext("Possible Index End Reason", "Other")
end
