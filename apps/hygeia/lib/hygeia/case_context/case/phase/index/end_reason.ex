defmodule Hygeia.CaseContext.Case.Phase.Index.EndReason do
  @moduledoc "Index Phase End Reason"

  use EctoEnum,
    type: :case_phase_index_end_reason,
    enums: [
      :healed,
      :death,
      :no_follow_up,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(end_reason)
  def translate(:healed), do: pgettext("Index End Reason", "Healed")
  def translate(:death), do: pgettext("Index End Reason", "Death")
  def translate(:no_follow_up), do: pgettext("Index End Reason", "No Follow Up")
  def translate(:other), do: pgettext("Index End Reason", "Other")
end
