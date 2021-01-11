defmodule HygeiaWeb.VersionLive.Change do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.LiveRedirect

  prop version, :map, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="component-version-live-change">
      {{ render_tree(@version.item_changes, item_type_to_module(@version.item_type), assigns) }}
    </div>
    """
  end

  defp render_tree(map, schema, assigns) when is_map(map) and not is_struct(map) do
    ~H"""
    <ul>
      <li :for={{
        {key, value} <- map,
        field_key = field_key(key),
        field_name = schema_field_name(field_key, schema),
        field_schema = field_schema(schema, field_key(key), value)
      }}>
        <details :if={{ is_complex?(value) }}>
          <summary><strong>{{ field_name }}</strong></summary>
          {{ render_tree(value, field_schema, assigns) }}
        </details>
        <span :if={{ not is_complex?(value) }}>
          <strong class="field-name">{{ field_name }}</strong>
          <LiveRedirect
            :if={{ is_foregin_key?(schema, field_key) }}
            to={{
              Routes.version_show_path(
                @socket,
                :show,
                schema |> get_field_relation_target_schema(field_key) |> module_to_item_type(),
                value
              )
            }}
          >
            {{ render_tree(value, field_schema, assigns) }}
          </LiveRedirect>
          <span :if={{ not is_foregin_key?(schema, field_key) }}>
            {{ render_tree(value, field_schema, assigns) }}
          </span>
        </span>
      </li>
    </ul>
    """
  end

  defp render_tree(nil, _schema, assigns) do
    ~H"""
    <span class="nil"></span>
    """
  end

  # credo:disable-for-next-line Credo.Check.Consistency.UnusedVariableNames
  defp render_tree([], _schema, assigns) do
    ~H"""
    <span class="empty-list"></span>
    """
  end

  defp render_tree(list, schema, assigns) when is_list(list) do
    ~H"""
    <div>
      <div :for={{ value <- list }}>
        {{ render_tree(value, schema, assigns) }}
      </div>
    </div>
    """
  end

  defp render_tree(scalar, _schema, _assings) when not is_struct(scalar), do: scalar

  defp is_foregin_key?(schema, field), do: get_field_relation_target_schema(schema, field) != nil

  defp get_field_relation_target_schema(schema, field) do
    :associations
    |> schema.__schema__()
    |> Enum.map(&schema.__schema__(:association, &1))
    |> Enum.find_value(fn
      %Ecto.Association.BelongsTo{owner_key: ^field, related: related} -> related
      _other -> false
    end)
  end

  defp is_complex?(nil), do: false
  defp is_complex?([]), do: false
  defp is_complex?(list) when is_list(list), do: true
  defp is_complex?(map) when map_size(map) == 0, do: false
  defp is_complex?(map) when is_map(map) and not is_struct(map), do: true
  defp is_complex?(other) when not (is_list(other) and not is_map(other)), do: false

  defp field_schema(schema, field, value) do
    :type
    |> schema.__schema__(field)
    |> case do
      {:parameterized, Ecto.Embedded, %Ecto.Embedded{related: sub_schema}} ->
        sub_schema

      atom when is_atom(atom) ->
        atom

      {:array, atom} when is_atom(atom) ->
        atom

      {:parameterized, PolymorphicEmbed, %{type_field: type_field, types_metadata: types}} ->
        current_type_name = value[type_field]

        Enum.find_value(types, fn
          %{type: ^current_type_name, module: module} -> module
          _other -> false
        end)

      _other ->
        raise "unknown"
    end
  end

  defp field_key(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> field
  end
end
