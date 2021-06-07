defmodule Hygeia.CaseContext.Case.Phase.PossibleIndex.Type do
  @moduledoc "Possible Index Phase Type"

  use EctoEnum,
    type: :case_phase_possible_index_type,
    enums: [
      :contact_person,
      :travel,
      :outbreak,
      :covid_app,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(end_reason)
  def translate(:contact_person), do: pgettext("Possible Index Type", "Contact Person")
  def translate(:travel), do: pgettext("Possible Index Type", "Travel")
  def translate(:outbreak), do: pgettext("Possible Index Type", "Outbreak Examination")
  def translate(:covid_app), do: pgettext("Possible Index Type", "CovidApp Alert")
  def translate(:other), do: pgettext("Possible Index Type", "Other")
end
