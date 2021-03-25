defmodule Hygeia.Country.ECH007210 do
  @moduledoc """
  ECH007210 schema
  """

  require Record

  path = Path.join(Path.dirname(__ENV__.file), "eCH-0072-1-0.xsd")

  hrl_path =
    path
    |> Path.dirname()
    |> Path.join(Path.basename(path, ".xsd") <> ".hrl")

  model =
    path
    |> File.read!()
    |> :erlsom.compile()
    |> case do
      {:ok, model} -> model
    end

  :erlsom.write_hrl(model, hrl_path)

  @external_resource path

  for {name, def} <- Record.extract_all(from: hrl_path) do
    firendly_name =
      name
      |> Atom.to_string()
      |> String.replace_leading("p:", "")
      |> String.to_atom()

    Record.defrecord(firendly_name, name, def)
  end

  @spec read(content :: String.t()) ::
          {:ok, structure :: term(), trailing_characters :: binary()} | {:error, term()}
  def read(content), do: :erlsom.scan(content, unquote(Macro.escape(model)))
end
