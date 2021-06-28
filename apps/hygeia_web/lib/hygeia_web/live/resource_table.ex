# credo:disable-for-this-file Credo.Check.Design.AliasUsage
defmodule HygeiaWeb.ResourceTable do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.LiveRedirect

  require Logger

  prop subject, :map, required: true
  prop module, :atom, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~F"""
    <div class="component-resource-table">
      <Context get={HygeiaWeb, timezone: timezone}>
        {render_tree(@subject, @module, assigns, timezone)}
      </Context>
    </div>
    """
  end

  defp render_tree(map, schema, assigns, timezone) when is_map(map) and not is_struct(map) do
    ~F"""
    <ul>
      <li :for={
        {key, value} <- map,
        field_key = field_key(key),
        field_schema = field_schema(schema, field_key(key), value),
        field_name = schema_field_name(field_key, schema)
      }>
        <details :if={is_complex?(value)}>
          <summary><strong>{field_name}</strong></summary>
          {render_tree(value, field_schema, assigns, timezone)}
        </details>
        <span :if={not is_complex?(value)}>
          <strong class="field-name">{field_name}</strong>
          <LiveRedirect
            :if={is_foregin_key?(schema, field_key) and not is_nil(value)}
            to={Routes.version_show_path(
              @socket,
              :show,
              schema |> get_field_relation_target_schema(field_key) |> module_to_item_table(),
              value
            )}
          >
            {render_tree(value, field_schema, assigns, timezone)}
          </LiveRedirect>
          <span :if={not is_foregin_key?(schema, field_key)}>
            {render_tree(value, field_schema, assigns, timezone)}
          </span>
        </span>
      </li>
    </ul>
    """
  end

  defp render_tree(nil, _schema, assigns, _timezone) do
    ~F"""
    <span class="nil" />
    """
  end

  # credo:disable-for-next-line Credo.Check.Consistency.UnusedVariableNames
  defp render_tree([], _schema, assigns, _timezone) do
    ~F"""
    <span class="empty-list" />
    """
  end

  defp render_tree(list, schema, assigns, timezone) when is_list(list) do
    ~F"""
    <div>
      <div :for={value <- list}>
        {render_tree(value, schema, assigns, timezone)}
      </div>
    </div>
    """
  end

  defp render_tree(string, schema, _assings, _timezone) when schema in [:string, :binary_id],
    do: string

  defp render_tree(country, Hygeia.EctoType.Country, _assigns, _timezone),
    do: country_name(country)

  defp render_tree(%Date{} = date, :date, _assigns, _timezone),
    do: HygeiaCldr.Date.to_string!(date)

  defp render_tree(date, :date, _assigns, _timezone) when is_binary(date),
    do:
      date
      |> Date.from_iso8601!()
      |> HygeiaCldr.Date.to_string!()

  for enum <- [
        Hygeia.CaseContext.Person.ContactMethod.Type,
        Hygeia.CaseContext.ExternalReference.Type,
        Hygeia.ImportContext.Import.Type,
        Hygeia.CaseContext.Person.Sex,
        Hygeia.CaseContext.Case.Status,
        Hygeia.CaseContext.Test.Kind
      ] do
    defp render_tree(value, unquote(enum), _assigns, _timezone) do
      {:ok, value} = unquote(enum).cast(value)
      unquote(enum).translate(value)
    end
  end

  defp render_tree(%NaiveDateTime{} = date, type, _assigns, timezone)
       when type in [:naive_datetime, :naive_datetime_usec],
       do:
         date
         |> DateTime.from_naive!("Etc/UTC")
         |> DateTime.shift_zone!(timezone)
         |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(
         %NaiveDateTime{} = date,
         Hygeia.EctoType.LocalizedNaiveDatetime,
         _assigns,
         timezone
       ),
       do:
         date
         |> DateTime.from_naive!(timezone)
         |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(date, type, _assigns, timezone)
       when type in [:naive_datetime, :naive_datetime_usec],
       do:
         date
         |> NaiveDateTime.from_iso8601!()
         |> DateTime.from_naive!("Etc/UTC")
         |> DateTime.shift_zone!(timezone)
         |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(date, Hygeia.EctoType.LocalizedNaiveDatetime, _assigns, timezone),
    do:
      date
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!(timezone)
      |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(%DateTime{} = date, type, _assigns, timezone)
       when type in [:utc_datetime, :datetime, :datetime_usec, :utc_datetime_usec],
       do: date |> DateTime.shift_zone!(timezone) |> HygeiaCldr.DateTime.to_string!()

  defp render_tree(date, type, assigns, timezone)
       when type in [:utc_datetime, :datetime, :datetime_usec, :utc_datetime_usec] and
              is_binary(date) do
    case DateTime.from_iso8601(date) do
      {:ok, date, _offset} ->
        date |> DateTime.shift_zone!(timezone) |> HygeiaCldr.DateTime.to_string!()

      {:error, :missing_offset} ->
        render_tree(date, :naive_datetime_usec, assigns, timezone)
    end
  end

  defp render_tree(code, Hygeia.EctoType.NOGA.Code, _assigns, _timezone) do
    {:ok, code} = Hygeia.EctoType.NOGA.Code.cast(code)
    Hygeia.EctoType.NOGA.Code.title(code)
  end

  defp render_tree(code, Hygeia.EctoType.NOGA.Section, _assigns, _timezone) do
    {:ok, code} = Hygeia.EctoType.NOGA.Section.cast(code)
    Hygeia.EctoType.NOGA.Section.title(code)
  end

  defp render_tree(true, :boolean, _assigns, _timezone), do: gettext("True")
  defp render_tree(false, :boolean, _assigns, _timezone), do: gettext("False")

  defp render_tree(other, schema, _assings, _timezone) do
    Logger.warn("""
    #{__MODULE__}.render_tree/34for #{inspect(schema)} not implemented
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
