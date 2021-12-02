defmodule Hygeia.Helpers.Calendar do
  @moduledoc false

  import Ecto.Changeset
  import HygeiaGettext

  @doc false
  @spec validate_past_date(
          changeset :: Ecto.Changeset.t(any),
          field :: atom()
        ) :: Ecto.Changeset.t()
  def validate_past_date(changeset, field),
    do: validate_past_date(changeset, field, dgettext("errors", "date must be in the past"))

  @doc false
  @spec validate_past_date(
          changeset :: Ecto.Changeset.t(any),
          field :: atom(),
          msg :: String.t()
        ) :: Ecto.Changeset.t()
  def validate_past_date(changeset, field, msg) do
    validate_change(changeset, field, fn ^field, value ->
      if Date.compare(value, Date.utc_today()) in [:lt, :eq] do
        []
      else
        [{field, msg}]
      end
    end)
  end
end
