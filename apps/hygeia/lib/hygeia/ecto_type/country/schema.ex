defmodule Hygeia.Country.Schema do
  @moduledoc false

  schema_paths =
    __ENV__.file
    |> Path.dirname()
    |> Path.join("/*.xsd")
    |> Path.wildcard()

  for path <- schema_paths do
    @external_resource path

    name =
      path
      |> Path.basename(".xsd")
      |> String.replace("-", "_")
      |> Macro.camelize()
      |> String.to_atom()

    model =
      path
      |> File.read!()
      |> :erlsom.compile()
      |> case do
        {:ok, model} -> model
      end

    hrl_path =
      path
      |> Path.dirname()
      |> Path.join(Path.basename(path, ".xsd") <> ".hrl")

    :erlsom.write_hrl(model, hrl_path)

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    defmodule Module.concat(__MODULE__, name) do
      @moduledoc """
      #{name} schema
      """

      require Record

      @external_resource path
      @external_resource hrl_path

      for {name, def} <- Record.extract_all(from: hrl_path) do
        firendly_name =
          name
          |> Atom.to_string()
          |> String.replace_leading("p:", "")
          |> String.to_atom()

        Record.defrecord(firendly_name, name, def)
      end

      @spec model :: term()
      def model, do: unquote(Macro.escape(model))

      @spec write(data :: term) :: {:ok, content :: binary()} | {:error, term()}
      def write(data), do: :erlsom.write(data, unquote(Macro.escape(model)), output: :binary)

      @spec read(content :: String.t()) ::
              {:ok, structure :: term(), trailing_characters :: binary()} | {:error, term()}
      def read(content), do: :erlsom.scan(content, unquote(Macro.escape(model)))
    end
  end
end
