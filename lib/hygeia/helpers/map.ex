# Code Extracted from: https://github.com/prodis/miss-elixir/blob/13901157e5e180e23071aaa7fbcb69ebd30bd8f2/lib/miss/map.ex
# License: https://github.com/prodis/miss-elixir/blob/13901157e5e180e23071aaa7fbcb69ebd30bd8f2/LICENSE
defmodule Hygeia.Helpers.Map do
  @moduledoc """
  Elixir.Map Helper
  """

  @type transform :: [{module(), (module() -> term()) | :skip}]

  @doc """
  Converts a `struct` to map going through all nested structs.
  The optional parameter `transform` receives a list of tuples with the struct module and a
  function to be called instead of converting to a map. The transforming function will receive the
  struct as a single parameter.
  If you want to skip the conversion of a nested struct, just pass the atom `:skip` instead of a
  transformation function.
  `Date` or `Decimal` values are common examples where their map representation could be not so
  useful when converted to a map - [{Date, :skip}, {Decimal, &to_string/1}]
  """
  @spec from_nested_struct(struct(), transform()) :: map()
  def from_nested_struct(struct, transform \\ []) when is_struct(struct),
    do: to_map(struct, transform)

  @spec to_map(term(), transform()) :: term()
  defp to_map(%module{} = struct, transform) do
    transform
    |> Keyword.get(module)
    |> case do
      nil ->
        struct
        |> Map.from_struct()
        |> to_nested_map(transform)

      fun when is_function(fun, 1) ->
        fun.(struct)

      :skip ->
        struct
    end
  end

  defp to_map(value, transform) when is_map(value),
    do: to_nested_map(value, transform)

  defp to_map(list, transform) when is_list(list),
    do: Enum.map(list, fn item -> to_map(item, transform) end)

  defp to_map(value, _transform), do: value

  @spec to_nested_map(map(), transform()) :: map()
  defp to_nested_map(map, transform) do
    map
    |> Map.keys()
    |> Enum.reduce(%{}, fn key, new_map ->
      value =
        map
        |> Map.get(key)
        |> to_map(transform)

      Map.put(new_map, key, value)
    end)
  end
end
