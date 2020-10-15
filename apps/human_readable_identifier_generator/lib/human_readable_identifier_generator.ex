defmodule HumanReadableIdentifierGenerator do
  @moduledoc """
  HumanReadableIdentifierGenerator
  """

  alias HumanReadableIdentifierGenerator.Storage

  defdelegate fetch(word, server \\ Storage), to: Storage

  @spec fetch_human_readable_id(id :: String.t(), server :: Agent.agent()) ::
          {:ok, String.t()} | :error
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def fetch_human_readable_id(id, server \\ Storage) when is_binary(id) do
    with ets_table_size when ets_table_size > 0 <- Storage.ets_table_size(server),
         first_part_crc32 <- :erlang.crc32(id),
         second_part_crc32 <- :erlang.crc32(id <> "2"),
         first_part_position <- Integer.mod(first_part_crc32, ets_table_size),
         {:ok, first_part_id} <- Storage.fetch(first_part_position, server),
         second_part_position <- Integer.mod(second_part_crc32, ets_table_size),
         {:ok, second_part_id} <- Storage.fetch(second_part_position, server),
         number_part_id <- Integer.mod(first_part_crc32, 100) do
      {:ok, "#{first_part_id}-#{second_part_id}-#{number_part_id}"}
    else
      _err -> :error
    end
  end
end
