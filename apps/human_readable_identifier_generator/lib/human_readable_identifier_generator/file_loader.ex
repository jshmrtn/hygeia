defmodule HumanReadableIdentifierGenerator.FileLoader do
  @moduledoc """
  File Loader
  """

  @spec read(file :: Path.t()) :: [String.t()]
  def read(file) do
    file
    |> File.stream!()
    |> Stream.filter(&Regex.match?(~r/^[[:alpha:]]+$/, &1))
    |> Stream.map(&Unidecode.decode/1)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.downcase/1)
    |> Stream.uniq()
    |> Enum.to_list()
  end
end
