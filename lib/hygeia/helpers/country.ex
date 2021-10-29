defmodule Hygeia.Helpers.Country do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset

  @spec validate_subdivision(
          changeset :: Changeset.t(resource),
          field :: atom,
          country_field :: atom
        ) ::
          Changeset.t(resource)
        when resource: term
  def validate_subdivision(changeset, field, country_field) do
    changeset
    |> fetch_field!(country_field)
    |> case do
      nil -> validate_inclusion(changeset, field, [nil])
      country -> validate_inclusion(changeset, field, Cadastre.Subdivision.ids(country))
    end
  end

  @spec validate_subdivision_required(
          changeset :: Changeset.t(resource),
          field :: atom,
          country_field :: atom
        ) :: Changeset.t(resource)
        when resource: term
  def validate_subdivision_required(changeset, field, country_field) do
    changeset
    |> fetch_field!(country_field)
    |> case do
      nil ->
        changeset

      country ->
        case Cadastre.Subdivision.ids(country) do
          [] -> changeset
          [_id | _other_ids] -> validate_required(changeset, [field])
        end
    end
  end
end
