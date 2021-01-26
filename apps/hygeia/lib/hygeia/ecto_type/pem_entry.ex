defmodule Hygeia.EctoType.PEMEntry do
  @moduledoc """
  Type for PEM
  """

  use Ecto.Type

  @impl Ecto.Type
  def type, do: :text

  @impl Ecto.Type
  def embed_as(_format), do: :dump

  @impl Ecto.Type
  def cast(binary) when is_binary(binary) do
    with [pem_entry_encoded] <- :public_key.pem_decode(binary),
         pem_entry <- :public_key.pem_entry_decode(pem_entry_encoded) do
      {:ok, pem_entry}
    else
      [] -> :error
      list when length(list) > 1 -> :error
    end
  end

  def cast(tuple) when is_tuple(tuple) do
    {:ok, tuple}
  end

  @impl Ecto.Type
  def load(binary) when is_binary(binary) do
    with [pem_entry_encoded] <- :public_key.pem_decode(binary),
         pem_entry <- :public_key.pem_entry_decode(pem_entry_encoded) do
      {:ok, pem_entry}
    else
      [] -> :error
      list when length(list) > 1 -> :error
    end
  end

  @impl Ecto.Type
  def dump(pem_entry) when is_tuple(pem_entry) do
    pem_entry_encoded = :public_key.pem_entry_encode(:RSAPublicKey, pem_entry)
    {:ok, :public_key.pem_encode([pem_entry_encoded])}
  end
end
