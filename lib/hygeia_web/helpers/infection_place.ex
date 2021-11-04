defmodule HygeiaWeb.Helpers.InfectionPlace do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.CaseContext.Transmission.InfectionPlace

  @spec infection_place_type_options :: [{String.t(), InfectionPlace.Type.t()}]
  def infection_place_type_options,
    do:
      InfectionPlace.Type.__enum_map__()
      |> Enum.map(&{translate_infection_place_type(&1), &1})
      |> Enum.sort()

  @spec translate_infection_place_type(type :: InfectionPlace.Type.t()) :: String.t()
  def translate_infection_place_type(:work_place), do: gettext("Work Place")
  def translate_infection_place_type(:army), do: gettext("Army, Civil Protection")
  def translate_infection_place_type(:asyl), do: gettext("Asylum Center")
  def translate_infection_place_type(:choir), do: gettext("Choir, Choral Society, Orchstra")

  def translate_infection_place_type(:club),
    do: gettext("Pub, Discotheque, Dance club, Night club")

  def translate_infection_place_type(:hh), do: gettext("Own Household")

  def translate_infection_place_type(:high_school),
    do:
      gettext(
        "Establishment of upper secondary level, tertiary educational institution or further training facility"
      )

  def translate_infection_place_type(:childcare),
    do: gettext("Facility for supplementary childcare")

  def translate_infection_place_type(:erotica), do: gettext("Adult salon / prostitution services")
  def translate_infection_place_type(:flight), do: gettext("Airplane or travel")

  def translate_infection_place_type(:medical),
    do:
      gettext(
        "Health care facility (hospital, clinic, doctor's practice, health care practice, establishment of health professionals according to federal and cantonal law)"
      )

  def translate_infection_place_type(:hotel),
    do: gettext("Hotel, place of accommodation, campsite, parking space for mobile homes")

  def translate_infection_place_type(:child_home),
    do: gettext("Children's home, home for the disabled")

  def translate_infection_place_type(:cinema), do: gettext("Cinema / theater / concert")
  def translate_infection_place_type(:shop), do: gettext("Shops / market")
  def translate_infection_place_type(:school), do: gettext("Compulsory school")

  def translate_infection_place_type(:less_300),
    do: gettext("Public or private event < 300 people")

  def translate_infection_place_type(:more_300),
    do: gettext("Public or private event > 300 people")

  def translate_infection_place_type(:public_transp), do: gettext("Public transport, cable cars")

  def translate_infection_place_type(:massage),
    do: gettext("Personal service with physical contact (e.g. hairdressers, massage studio)")

  def translate_infection_place_type(:nursing_home), do: gettext("Retirement / nursing home")
  def translate_infection_place_type(:religion), do: gettext("Religious gatherings / funerals")
  def translate_infection_place_type(:restaurant), do: gettext("Restaurant")
  def translate_infection_place_type(:school_camp), do: gettext("School / scout camp")
  def translate_infection_place_type(:indoor_sport), do: gettext("Indoor Sport activities")
  def translate_infection_place_type(:outdoor_sport), do: gettext("Outdoor Sport activities")
  def translate_infection_place_type(:gathering), do: gettext("Meeting with family / friends")
  def translate_infection_place_type(:zoo), do: gettext("Zoos, animal parks, gardens")
  def translate_infection_place_type(:prison), do: gettext("Correctional facility")
  def translate_infection_place_type(:other), do: gettext("another place")
end
