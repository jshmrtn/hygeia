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

  @spec subdivisions(form_source :: Phoenix.HTML.FormData.t()) :: [{String.t(), String.t()}]
  def subdivisions(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.fetch_field!(:country)
    |> _subdivisions()
  end

  def subdivisions(%{} = form_data) do
    _subdivisions(form_data[:country] || form_data["country"])
  end

  defp _subdivisions(nil), do: []

  defp _subdivisions(country) do
    locale = HygeiaCldr.get_locale().language

    country
    |> Cadastre.Subdivision.all()
    |> Enum.map(&{Cadastre.Subdivision.name(&1, locale), &1.id})
    |> Enum.sort_by(&elem(&1, 0))
  end
end
