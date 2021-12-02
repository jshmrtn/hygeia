defmodule Hygeia.Helpers.Calendar do
  import Ecto.Changeset
  import HygeiaGettext

  # TODO: Use HTML <input type="date"> min and max options once they are fixed in Phoenix
  # Related issue: https://github.com/jshmrtn/hygeia/issues/930#issuecomment-984785198

  @doc false
  @spec validate_past_date(
          changeset :: Changeset.t(any),
          field :: atom()
        ) :: Changeset.t()
  def validate_past_date(changeset, field),
    do: validate_past_date(changeset, field, dgettext("errors", "date must be in the past"))

  @doc false
  @spec validate_past_date(
          changeset :: Changeset.t(any),
          field :: atom(),
          msg :: String.t()
        ) :: Changeset.t()
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
