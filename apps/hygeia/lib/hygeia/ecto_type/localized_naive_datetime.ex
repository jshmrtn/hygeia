defmodule Hygeia.EctoType.LocalizedNaiveDatetime do
  @moduledoc """
  Type for NaiveDatetime converted to local timezone
  """

  use Ecto.Type

  @type t :: NaiveDateTime.t()

  @database_timezone "Etc/UTC"

  @impl Ecto.Type
  def type, do: :naive_datetime_usec

  @impl Ecto.Type
  def load(%NaiveDateTime{} = naive_datetime) do
    {:ok, convert(naive_datetime, @database_timezone, local_timezone())}
  end

  def load(_other), do: :error

  @impl Ecto.Type
  def dump(%NaiveDateTime{} = naive_datetime) do
    {:ok, convert(naive_datetime, local_timezone(), @database_timezone)}
  end

  def dump(_other), do: :error

  @impl Ecto.Type
  def cast(naive_datetime) do
    Ecto.Type.cast(:naive_datetime_usec, naive_datetime)
  end

  defp convert(naive_datetime, from_timezone, to_timezone) do
    naive_datetime
    |> DateTime.from_naive!(from_timezone)
    |> DateTime.shift_zone!(to_timezone)
    |> DateTime.to_naive()
  end

  #   TODO read timezone from user/session
  defp local_timezone, do: "Europe/Zurich"
end
