defmodule Hygeia.EctoType.DateRange do
  @moduledoc """
  `Date.Range` type for Ecto
  """

  use Ecto.Type

  @type t :: Date.Range.t()

  @impl Ecto.Type
  def type, do: :daterange

  @impl Ecto.Type
  def cast(term)

  def cast(%Date.Range{} = range) do
    {:ok, range}
  end

  def cast(_other), do: :error

  @impl Ecto.Type
  def load(term)

  def load(%Postgrex.Range{lower: %Date{} = lower, lower_inclusive: false} = range),
    do: load(%Postgrex.Range{range | lower_inclusive: true, lower: Date.add(lower, 1)})

  def load(%Postgrex.Range{upper: %Date{} = upper, upper_inclusive: false} = range),
    do: load(%Postgrex.Range{range | upper_inclusive: true, upper: Date.add(upper, -1)})

  def load(%Postgrex.Range{
        lower: %Date{} = lower,
        lower_inclusive: true,
        upper: %Date{} = upper,
        upper_inclusive: true
      }),
      do: {:ok, Date.range(lower, upper)}

  def load(_other), do: :error

  @impl Ecto.Type
  def dump(%Date.Range{first: lower, last: upper, step: 1}),
    do:
      {:ok,
       %Postgrex.Range{lower: lower, lower_inclusive: true, upper: upper, upper_inclusive: true}}

  def dump(_other), do: :error
end
