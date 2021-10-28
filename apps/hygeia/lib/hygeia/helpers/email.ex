defmodule Hygeia.Helpers.Email do
  @moduledoc false

  import Ecto.Changeset

  import HygeiaGettext

  alias Ecto.Changeset

  @spec validate_email(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  def validate_email(changeset, field) do
    changeset
    |> fetch_change(field)
    |> case do
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:ok, email} ->
        if EmailChecker.valid?(email) do
          changeset
        else
          add_error(changeset, field, dgettext("errors", "is invalid"))
        end
    end
  end
end
