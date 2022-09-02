defmodule HygeiaWeb.RowLive.Changes do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.Repo

  prop row, :map
  prop data, :map

  slot field_value, arg: %{key: :strin, value: :any}

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do:
      preload_assigns_one(
        assign_list,
        :row,
        &Repo.preload(&1, :import),
        & &1.uuid
      )

  defp group_fields(%ImportContext.Row{import: %ImportContext.Import{type: import_type}}, data) do
    grouping = Type.display_field_grouping(import_type)

    data
    |> Enum.reduce(%{}, fn {field, value}, acc ->
      field_canonical = field |> String.downcase() |> String.trim()

      grouping
      |> Enum.find_value(fn {group_name, fields} ->
        MapSet.member?(fields, field_canonical) && group_name
      end)
      |> case do
        nil ->
          acc

        group_name ->
          Map.update(acc, group_name, [{field, value}], &[{field, value} | &1])
      end
    end)
    |> Enum.map(fn {group, fields} ->
      {group, Enum.sort(fields)}
    end)
    |> Enum.sort()
  end

  defp value_or_default(value, default)
  defp value_or_default(nil, default), do: default
  defp value_or_default("", default), do: default
  defp value_or_default(value, _default), do: value
end
