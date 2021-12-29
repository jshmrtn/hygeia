defmodule Hygeia.CaseContext.Person.VaccinationShot.VaccineType do
  @moduledoc """
  Vaccine Type Enum
  """

  use Hygeia, :model

  use EctoEnum,
    type: :vaccine_type,
    enums: [
      :pfizer,
      :moderna,
      :janssen,
      :other
    ]

  import HygeiaGettext

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:pfizer),
    do: pgettext("Vaccine Type", "Pfizer/BioNTech (Comirnaty® / BNT162b2 / Tozinameran)")

  def translate(:moderna),
    do: pgettext("Vaccine Type", "Moderna (Spikevax® / mRNA-1273 / COVID-19 vaccine)")

  def translate(:janssen), do: pgettext("Vaccine Type", "Janssen (COVID-19 Vaccine Janssen®)")
  def translate(:other), do: pgettext("Vaccine Type", "Other")
end
