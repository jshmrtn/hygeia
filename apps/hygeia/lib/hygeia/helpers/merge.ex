defmodule Hygeia.Helpers.Merge do
  @moduledoc false

  @spec merge(
          old :: schema,
          new :: schema,
          module :: module,
          embed_callback :: (embed :: atom, old_embed :: embed, new_embed :: embed -> embed)
        ) :: schema
        when schema: Ecto.Schema.t(), embed: Ecto.Schema.t()
  def merge(old, new, module, embed_callback \\ &embed_merge_raise/3) do
    result =
      :fields
      |> module.__schema__()
      |> Kernel.--(module.__schema__(:embeds))
      |> Enum.map(&{&1, Map.fetch!(new, &1)})
      |> Enum.reduce(old, fn
        {_key, nil}, acc -> acc
        {key, value}, acc -> Map.put(acc, key, value)
      end)

    :embeds
    |> module.__schema__()
    |> Enum.map(&{&1, Map.fetch!(new, &1)})
    |> Enum.reduce(result, fn
      {_embed, nil}, acc ->
        acc

      {embed, new_embed}, acc ->
        result_embed =
          acc
          |> Map.fetch!(embed)
          |> case do
            nil -> new_embed
            old_embed -> embed_callback.(embed, old_embed, new_embed)
          end

        Map.put(acc, embed, result_embed)
    end)
  end

  @spec embed_merge_raise(embed :: atom, old_embed :: struct, new_embed :: struct) :: no_return
  defp embed_merge_raise(_embed, _old_embed, _new_embed), do: raise("No Callback Supplied")
end
