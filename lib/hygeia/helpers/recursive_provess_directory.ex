defmodule Hygeia.Helpers.RecursiveProcessDirectory do
  @moduledoc false

  @spec get(pids :: [pid], key :: {module, atom}, default :: default) :: term | default
        when default: term

  def get(pids, key, default \\ nil)

  def get([], _key, default), do: default

  def get(pids, key, default) do
    dictionarys =
      pids
      |> Enum.map(&Process.info(&1, :dictionary))
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&Map.new/1)

    Enum.find_value(dictionarys, fn
      %{^key => value} -> value
      _other -> false
    end) ||
      dictionarys
      |> Enum.flat_map(&Map.get(&1, :"$ancestors", []))
      |> Enum.map(fn
        pid when is_pid(pid) -> pid
        atom when is_atom(atom) -> Process.whereis(atom)
      end)
      |> get(key, default)
  end
end
