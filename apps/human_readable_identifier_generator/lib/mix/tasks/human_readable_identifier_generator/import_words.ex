defmodule Mix.Tasks.HumanReadableIdentifierGenerator.ImportWords do
  @shortdoc "Import Wordlist"

  @moduledoc """
  Import Word List
  """

  use Mix.Task

  alias HumanReadableIdentifierGenerator.FileLoader

  @default_base_path Application.app_dir(:human_readable_identifier_generator, "priv/data/prod")

  @impl Mix.Task
  def run([base_path]) when is_binary(base_path) do
    _run(base_path)
  end

  def run([]) do
    _run(@default_base_path)
  end

  defp _run(base_path) do
    Application.ensure_all_started(:unidecode)

    import_path = Path.join(base_path, "latin.txt")

    dets_path = Path.join(base_path, "latin.dets")

    if File.exists?(dets_path) do
      File.rm!(dets_path)
    end

    {:ok, dets} = :dets.open_file(String.to_charlist(dets_path), type: :set)

    import_path
    |> FileLoader.read()
    |> tee(&store_data(&1, dets))

    :dets.close(dets)

    :ok
  end

  defp tee(input, function) do
    function.(input)
    input
  end

  defp store_data(words, dets) do
    words
    |> Stream.with_index()
    |> Enum.each(fn {word, index} ->
      :dets.insert(dets, {index, word})
    end)
  end
end
