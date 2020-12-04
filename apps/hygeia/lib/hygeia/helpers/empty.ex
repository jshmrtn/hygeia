defmodule Hygeia.Helpers.Empty do
  @moduledoc false

  alias Ecto.Changeset

  @spec is_empty?(changeset :: Changeset.t(), extra_ignore_fields :: [atom()]) :: boolean
  def is_empty?(changeset, extra_ignore_fields \\ []),
    do: drop_recursively(changeset, extra_ignore_fields) == %{}

  defp drop_recursively(%Changeset{changes: changes}, extra_ignore_fields),
    do: drop_recursively(changes, extra_ignore_fields)

  defp drop_recursively(%{} = changes, extra_ignore_fields) when not is_struct(changes) do
    changes
    |> Map.drop([:uuid, :inserted_at, :created_at] ++ extra_ignore_fields)
    |> Enum.map(&{elem(&1, 0), drop_recursively(elem(&1, 1), extra_ignore_fields)})
    |> Enum.reject(&match?({_key, value} when value == %{}, &1))
    |> Map.new()
  end

  defp drop_recursively(changes, _extra_ignore_fields), do: changes
end
