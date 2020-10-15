defmodule HumanReadableIdentifierGenerator.Storage do
  @moduledoc """
  Storage of Words
  """

  use Agent

  @server __MODULE__

  @spec start_link(options :: Keyword.t()) :: Agent.on_start()
  def start_link(options) do
    base_path = Keyword.get(options, :base_path, default_base_path())

    Agent.start_link(
      fn ->
        base_path
        |> Path.join("latin.dets")
        |> dets_to_ets(:human_readable_identifier_generator_words)
      end,
      name: Keyword.get(options, :name, @server)
    )
  end

  @spec ets_table_size(server :: Agent.agent()) :: non_neg_integer()
  def ets_table_size(server \\ @server) do
    ets_table = Agent.get(server, & &1)

    {:size, size} =
      ets_table
      |> :ets.info()
      |> List.keyfind(:size, 0)

    size
  end

  @spec fetch(word_position :: non_neg_integer(), server :: Agent.agent()) ::
          {:ok, String.t()} | :error
  def fetch(word_position, server \\ @server) do
    server
    |> Agent.get(& &1)
    |> :ets.lookup(word_position)
    |> case do
      [] ->
        :error

      [{^word_position, word}] ->
        {:ok, word}
    end
  end

  defp dets_to_ets(dets_path, name) do
    {:ok, dets} =
      dets_path
      |> String.to_charlist()
      |> :dets.open_file(type: :set, access: :read)

    table = :ets.new(name, [:ordered_set, :public])

    :dets.to_ets(dets, table)

    :dets.close(dets)

    table
  end

  defp default_base_path,
    do: Application.app_dir(:human_readable_identifier_generator, "priv/data/prod")
end
