defmodule Hygeia.CaseContext.Case.Monitoring.IsolationLocation do
  @moduledoc "Phase Type"

  use EctoEnum,
    type: :isolation_location,
    enums: [
      :home,
      :social_medical_facility,
      :hospital,
      :hotel,
      :asylum_center,
      :other
    ]

  import HygeiaGettext

  alias Hygeia.CaseContext.Case.Monitoring

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: Monitoring.IsolationLocation.t()) :: String.t()
  def translate(:home), do: gettext("Home")

  def translate(:social_medical_facility),
    do: gettext("Social medical facility")

  def translate(:hospital), do: gettext("Hospital")
  def translate(:hotel), do: gettext("Hotel")
  def translate(:asylum_center), do: gettext("Asylum center")
  def translate(:other), do: gettext("Other")
end
