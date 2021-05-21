# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule HygeiaWeb.VersionLive.Change do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Case.Status
  alias Surface.Components.LiveRedirect

  require Logger

  prop version, :map, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="component-version-live-change">
      {{ render_tree(@version.item_changes, item_table_to_module(@version.item_table), assigns) }}
    </div>
    """
  end

  defp render_tree(map, schema, assigns) when is_map(map) and not is_struct(map) do
    ~H"""
    <ul>
      <li :for={{
        {key, value} <- map,
        field_key = field_key(key),
        field_schema = field_schema(schema, field_key(key), value),
        field_name = schema_field_name(field_key, schema)
      }}>
        <details :if={{ is_complex?(value) }}>
          <summary><strong>{{ field_name }}</strong></summary>
          {{ render_tree(value, field_schema, assigns) }}
        </details>
        <span :if={{ not is_complex?(value) }}>
          <strong class="field-name">{{ field_name }}</strong>
          <LiveRedirect
            :if={{ is_foregin_key?(schema, field_key) and not is_nil(value) }}
            to={{Routes.version_show_path(
              @socket,
              :show,
              schema |> get_field_relation_target_schema(field_key) |> module_to_item_table(),
              value
            )}}
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
    <span class="nil" />
    """
  end

  # credo:disable-for-next-line Credo.Check.Consistency.UnusedVariableNames
  defp render_tree([], _schema, assigns) do
    ~H"""
    <span class="empty-list" />
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

  defp render_tree(string, schema, _assings) when schema in [:string, :binary_id], do: string
  defp render_tree(country, Hygeia.EctoType.Country, _assigns), do: country_name(country)

  defp render_tree(date, :date, _assigns),
    do: date |> Date.from_iso8601!() |> HygeiaCldr.Date.to_string!()

  defp render_tree(type, Hygeia.CaseContext.Person.ContactMethod.Type, _assigns),
    do: type |> String.to_existing_atom() |> translate_contact_method_type()

  defp render_tree(type, Hygeia.CaseContext.ExternalReference.Type, _assigns),
    do: type |> String.to_existing_atom() |> translate_external_reference_type()

  defp render_tree(date, type, _assigns) when type in [:naive_datetime, :naive_datetime_usec],
    do:
      date
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!("Europe/Zurich")
      |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(date, type, assigns)
       when type in [:utc_datetime, :datetime, :datetime_usec, :utc_datetime_usec] do
    case DateTime.from_iso8601(date) do
      {:ok, date, _offset} ->
        date |> DateTime.shift_zone!("Europe/Zurich") |> HygeiaCldr.DateTime.to_string!()

      {:error, :missing_offset} ->
        render_tree(date, :naive_datetime_usec, assigns)
    end
  end

  defp render_tree(code, Hygeia.EctoType.NOGA.Code, _assigns),
    do: code |> String.to_existing_atom() |> Hygeia.EctoType.NOGA.Code.title()

  defp render_tree(code, Hygeia.EctoType.NOGA.Section, _assigns),
    do: code |> String.to_existing_atom() |> Hygeia.EctoType.NOGA.Section.title()

  defp render_tree(sex, Hygeia.CaseContext.Person.Sex, _assigns),
    do: sex |> String.to_existing_atom() |> translate_person_sex()

  defp render_tree(boolean, :boolean, _assigns),
    do: if(boolean, do: gettext("True"), else: gettext("False"))

  defp render_tree(status, Hygeia.CaseContext.Case.Status, _assigns),
    do: status |> String.to_existing_atom() |> Status.translate()

  defp render_tree(other, schema, _assings) do
    Logger.warn("""
    #{__MODULE__}.render_tree/3 for #{inspect(schema)} not implemented
    """)

    other
  end

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
