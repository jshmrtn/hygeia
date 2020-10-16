defmodule HygeiaWeb.RegionHelpers do
  @moduledoc """
  countries and subdivisions
  """

  @spec countries :: [{String.t(), String.t()}]
  def countries do
    locale = HygeiaWeb.Cldr.get_locale().language

    Enum.map(
      Cadastre.Country.ids(),
      &{&1 |> Cadastre.Country.new() |> Cadastre.Country.name(locale), &1}
    )
  end

  @spec subdivisions(changeset :: Ecto.Changeset.t()) :: [{String.t(), String.t()}]
  def subdivisions(changeset) do
    locale = HygeiaWeb.Cldr.get_locale().language

    changeset
    |> Ecto.Changeset.fetch_field!(:country)
    |> case do
      nil ->
        []

      country ->
        Enum.map(
          Cadastre.Subdivision.all(country),
          &{Cadastre.Subdivision.name(&1, locale), &1.id}
        )
    end
  end
end
