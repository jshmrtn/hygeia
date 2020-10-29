defmodule Hygeia.Helpers.Phone do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset

  @phone_number_parsing_origin_country Application.fetch_env!(
                                         :hygeia,
                                         :phone_number_parsing_origin_country
                                       )

  @spec validate_and_normalize_phone(changeset :: Changeset.t(), field :: atom) :: Changeset.t()
  def validate_and_normalize_phone(changeset, field) do
    with {:ok, phone_number} <- fetch_change(changeset, field),
         {:ok, parsed_number} <-
           ExPhoneNumber.parse(phone_number, @phone_number_parsing_origin_country),
         true <- ExPhoneNumber.is_valid_number?(parsed_number) do
      put_change(changeset, field, ExPhoneNumber.Formatting.format(parsed_number, :e164))
    else
      :error ->
        changeset

      {:ok, nil} ->
        changeset

      {:error, _reason} ->
        add_error(changeset, field, "is invalid")

      false ->
        add_error(changeset, field, "is invalid")
    end
  end
end
