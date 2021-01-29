defmodule HygeiaXml do
  @moduledoc """
  Hygeia XML Schema Helper
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      require Record

      path = Keyword.fetch!(opts, :path)

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
