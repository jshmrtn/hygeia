defmodule Hygeia.EctoType.IP do
  @moduledoc """
  Implements Ecto.Type behavior for storing IP (either v4 or v6) data that originally comes as tuples.
  """

  use Ecto.Type

  @impl Ecto.Type
  def type, do: :inet

  @impl Ecto.Type
  def cast({_1, _2, _3, _4} = ipv4), do: {:ok, ipv4}
  def cast({_1, _2, _3, _4, _5, _6, _7, _8} = ipv6), do: {:ok, ipv6}

  def cast(ip) when is_binary(ip) do
    ip
    |> String.to_charlist()
    |> :inet.parse_address()
    |> case do
      {:ok, ip} -> {:ok, ip}
      {:error, _reason} -> :error
    end
  end

  @impl Ecto.Type
  def load(%Postgrex.INET{address: address}), do: {:ok, address}

  @impl Ecto.Type
  def dump(address), do: {:ok, %Postgrex.INET{address: address}}
end
