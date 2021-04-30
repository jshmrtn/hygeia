defmodule Hygeia.CaseContext.ExternalReference.Type do
  @moduledoc """
  External Reference Type
  """

  use EctoEnum,
    type: :external_reference_type,
    enums: [:ism_case, :ism_report, :ism_patient, :other]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:ism_case), do: pgettext("External Reference Type", "ISM Case")
  def translate(:ism_report), do: pgettext("External Reference Type", "ISM Report")
  def translate(:ism_patient), do: pgettext("External Reference Type", "ISM Patient")
  def translate(:other), do: pgettext("External Reference Type", "Other")
end
