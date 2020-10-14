defmodule Hygeia.Helpers.PostgresError do
  @moduledoc false

  alias Ecto.Changeset

  @type catch_error_spec ::
          {raised_message :: String.t(), changeset_error_field :: atom,
           changeset_error_message :: String.t()}

  @spec normalize_exceptions(changeset, (changeset -> result), [catch_error_spec]) ::
          result | {:error, Changeset.t()}
        when changeset: Changeset.t(), result: term
  def normalize_exceptions(%Changeset{} = changeset, callback, catch_errors)
      when is_function(callback, 1) and is_list(catch_errors) do
    callback.(changeset)
  rescue
    error in Postgrex.Error ->
      catch_errors
      |> Enum.find(fn {raised_message, _changeset_error_field, _changeset_error_message} ->
        match?(%Postgrex.Error{postgres: %{message: ^raised_message}}, error)
      end)
      |> case do
        nil ->
          reraise error, __STACKTRACE__

        {_raised_message, changeset_error_field, changeset_error_message} ->
          {:error, Changeset.add_error(changeset, changeset_error_field, changeset_error_message)}
      end
  end
end
