defmodule Hygeia.Helpers.Empty do
  @moduledoc false

  alias Ecto.Changeset

  @spec is_empty?(changeset :: Changeset.t()) :: boolean
  def is_empty?(changeset), do: drop_recursively(changeset) == %{}

  defp drop_recursively(%Changeset{changes: changes}), do: drop_recursively(changes)

  defp drop_recursively(%{} = changes) when not is_struct(changes) do
    changes
    |> Map.drop([:uuid, :inserted_at, :created_at])
    |> Enum.map(&{elem(&1, 0), drop_recursively(elem(&1, 1))})
    |> Enum.reject(&match?({_key, value} when value == %{}, &1))
    |> Map.new()
  end

  defp drop_recursively(changes), do: changes
end
