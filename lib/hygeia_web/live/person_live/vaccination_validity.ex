defmodule HygeiaWeb.PersonLive.VaccinationValidity do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Hygeia.CaseContext.Person.VaccinationShot.Validity

  @vaccination_refresh_interval_ms Hygeia.Jobs.Supervisor.vaccination_refresh_interval_ms()

  prop validities, :list, required: true
  prop shots, :list, required: true

  @foph_links %{
    "en" =>
      "https://www.bag.admin.ch/bag/en/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/impfen.html#-370631481",
    "it" =>
      "https://www.bag.admin.ch/bag/it/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/impfen.html#-121893401",
    "fr" =>
      "https://www.bag.admin.ch/bag/fr/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/impfen.html#1591829664",
    "de" =>
      "https://www.bag.admin.ch/bag/de/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/impfen.html#-190878347"
  }

  defp explanation_text do
    gettext_comment(
      "surounding text: The validity is only calculated for vaccines that are {link}."
    )

    link_text = pgettext("Vaccination Validity", "recognized by the FOPH")

    gettext_comment("link text: recognized by the FOPH")

    raw(
      pgettext(
        "Vaccination Validity",
        "The validity is only calculated for vaccines that are {link}.",
        link:
          safe_to_string(
            link(link_text,
              to: @foph_links[HygeiaCldr.get_locale().language] || @foph_links["en"],
              target: "_blank"
            )
          )
      )
    )
  end

  defp validity_likely_outdated?(shots),
    do:
      Enum.any?(
        shots,
        &(DateTime.diff(DateTime.utc_now(), &1.updated_at, :millisecond) <
            @vaccination_refresh_interval_ms)
      )

  defp refresh_interval do
    unit = Cldr.Unit.new!(@vaccination_refresh_interval_ms, :millisecond)
    lokalized = HygeiaCldr.Unit.localize(unit, HygeiaCldr, [])
    HygeiaCldr.Unit.to_string!(lokalized, format: :short)
  end
end
