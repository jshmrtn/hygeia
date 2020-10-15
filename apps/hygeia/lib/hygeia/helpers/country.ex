defmodule Hygeia.Helpers.Country do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset

  @spec validate_country(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  def validate_country(changeset, field),
    do: validate_inclusion(changeset, field, Cadastre.Country.ids())

  @spec validate_subdivision(changeset :: Changeset.t(), field :: atom, country_field :: atom) ::
          Changeset.t()
  def validate_subdivision(changeset, field, country_field) do
    changeset
    |> fetch_field!(country_field)
    |> case do
      nil -> validate_inclusion(changeset, field, [nil])
      country -> validate_inclusion(changeset, field, Cadastre.Subdivision.ids(country))
    end
  end
end
