defmodule Hygeia.CaseContext.Test.Kind do
  @moduledoc "Test Kind"

  use EctoEnum,
    type: :test_kind,
    enums: [
      :pcr,
      :serology,
      :quick,
      :antigen_quick,
      :antibody
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t()) :: String.t()
  def translate(:pcr), do: pgettext("Test Kind", "PCR")
  def translate(:quick), do: pgettext("Test Kind", "PCR Quick")
  def translate(:serology), do: pgettext("Test Kind", "Serology")
  def translate(:antigen_quick), do: pgettext("Test Kind", "Antigen Quick")
  def translate(:antibody), do: pgettext("Test Kind", "Antibody")
end
