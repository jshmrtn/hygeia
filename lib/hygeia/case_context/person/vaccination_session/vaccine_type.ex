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
      :astra_zeneca,
      :sinopharm,
      :sinovac,
      :covaxin,
      :novavax,
      :other
    ]

  @spec map :: [{String.t(), t}]
  def map, do: Enum.map(__enum_map__(), &{translate(&1), &1})

  @spec translate(type :: t) :: String.t()
  def translate(:pfizer), do: "Pfizer/BioNTech (BNT162b2 / Comirnaty® / Tozinameran)"
  def translate(:moderna), do: "Moderna (mRNA-1273 / Spikevax / COVID-19 vaccine Moderna)"
  def translate(:janssen), do: "Janssen / Johnson & Johnson (Ad26.COV2.S)"
  def translate(:astra_zeneca), do: "AstraZeneca (AZD1222 Vaxzevria®/ Covishield™)"
  def translate(:sinopharm), do: "Sinopharm / BIBP (SARS-CoV-2 Vaccine (Vero Cell))"
  def translate(:sinovac), do: "Sinovac (CoronaVac)"
  def translate(:covaxin), do: "COVAXIN®"
  def translate(:novavax), do: "Novavax (NVX-CoV2373 / Nuvaxovid™/ CovovaxTM)"
  def translate(:other), do: "Other"
end
