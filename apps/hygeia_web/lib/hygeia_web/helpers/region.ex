defmodule HygeiaWeb.Helpers.Region do
  @moduledoc """
  countries and subdivisions
  """

  @spec countries :: [{String.t(), String.t()}]
  def countries do
    locale = HygeiaCldr.get_locale().language

    Cadastre.Country.ids()
    |> Enum.map(&{&1 |> Cadastre.Country.new() |> Cadastre.Country.name(locale), &1})
    |> Enum.sort_by(&elem(&1, 0))
  end

  @spec subdivisions(form_source :: Phoenix.HTML.FormData.t(), default :: String.t() | nil) :: [
          {String.t(), String.t()}
        ]
  def subdivisions(form_source, default \\ nil)

  def subdivisions(%Ecto.Changeset{} = changeset, default) do
    changeset
    |> Ecto.Changeset.fetch_field!(:country)
    |> case do
      nil -> default
      "" -> default
      other -> other
    end
    |> _subdivisions()
  end

  def subdivisions(%{} = form_data, default) do
    _subdivisions(form_data[:country] || form_data["country"] || default)
  end

  defp _subdivisions(nil), do: []

  defp _subdivisions(country) do
    locale = HygeiaCldr.get_locale().language

    country
    |> Cadastre.Subdivision.all()
    |> Enum.map(&{Cadastre.Subdivision.name(&1, locale), &1.id})
    |> Enum.sort_by(&elem(&1, 0))
  end

  @spec country_name(country_code :: String.t()) :: String.t()
  def country_name(country_code) do
    locale = HygeiaCldr.get_locale().language

    country_code |> Cadastre.Country.new() |> Cadastre.Country.name(locale)
  end
end
