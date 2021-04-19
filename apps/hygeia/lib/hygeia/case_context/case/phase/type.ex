defmodule Hygeia.CaseContext.Case.Phase.Type do
  @moduledoc "Phase Type"

  use EctoEnum,
    type: :case_phase_type,
    enums: [
      :index,
      :possible_index
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:index), do: pgettext("Case Phase Type", "Index")
  def translate(:possible_index), do: pgettext("Case Phase Type", "Possible Index")
end
