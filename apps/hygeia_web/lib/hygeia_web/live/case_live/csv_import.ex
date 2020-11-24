defmodule HygeiaWeb.CaseLive.CSVImport do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Surface.Components.Link

  @mime_type_csv MIME.type("csv")
  @mime_type_xlsx MIME.type("xlsx")

  prop mapping, :map, required: true
  prop normalize_row_callback, :fun, required: true

  data show_help, :boolean, default: false

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, file: nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{data: data, content_type: [mime]} = assigns, socket) when mime == @mime_type_csv do
    extract_data(
      :csv,
      data,
      assigns[:mapping] || socket.assigns.mapping,
      assigns[:normalize_row_callback] || socket.assigns.normalize_row_callback
    )

    {:ok, assign(socket, assigns)}
  end

  def update(%{data: data, content_type: [mime]} = assigns, socket)
      when mime == @mime_type_xlsx do
    extract_data(
      :xlsx,
      data,
      assigns[:mapping] || socket.assigns.mapping,
      assigns[:normalize_row_callback] || socket.assigns.normalize_row_callback
    )

    {:ok, assign(socket, assigns)}
  end

  def update(
        %{
          data: _data,
          content_type: [_mime]
        } = assigns,
        socket
      ) do
    send(self(), {:csv_import, {:error, :not_supported}})

    {:ok, assign(socket, assigns)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  @dialyzer {:nowarn_function, {:handle_event, 3}}
  def handle_event("phx-dropzone", ["generate-url", %{"id" => id} = _payload], socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "uploads:#{id}")

    {:noreply, assign(socket, file: %{id: id, url: Routes.upload_url(socket, :upload, id)})}
  end

  def handle_event("phx-dropzone", ["file-status", _payload], socket) do
    {:noreply, socket}
  end

  def handle_event("show_help", _params, socket) do
    {:noreply, assign(socket, show_help: true)}
  end

  def handle_event("hide_help", _params, socket) do
    {:noreply, assign(socket, show_help: false)}
  end

  defp extract_data(:csv, data, mapping, normalize_row_callback) do
    mapping =
      mapping
      |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
      |> Enum.uniq()
      |> Map.new()

    normalized_rows =
      data
      |> String.split("\n")
      |> Enum.reject(&match?("", &1))
      |> CSV.decode!(headers: true)
      |> Stream.map(&normalize_row(&1, mapping, normalize_row_callback))

    send(self(), {:csv_import, {:ok, normalized_rows}})
  rescue
    e in FunctionClauseError -> send(self(), {:csv_import, {:error, e}})
  end

  defp extract_data(:xlsx, data, mapping, normalize_row_callback) do
    mapping =
      mapping
      |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
      |> Enum.uniq()
      |> Map.new()

    path = Briefly.create!(extname: ".xlsx")
    File.write!(path, data)

    normalized_rows =
      path
      |> Xlsxir.stream_list(0)
      |> Stream.transform(false, &add_headers/2)
      |> Stream.map(&normalize_row(&1, mapping, normalize_row_callback))

    send(self(), {:csv_import, {:ok, normalized_rows}})
  rescue
    e in FunctionClauseError -> send(self(), {:csv_import, {:error, e}})
  end

  defp normalize_row(row, key_mapping, normalize_row_callback) do
    row
    |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
    |> Enum.filter(fn {key, _value} -> Map.has_key?(key_mapping, key) end)
    |> Enum.map(fn {key, value} -> {key_mapping[key], value} end)
    |> Enum.map(&normalize_date/1)
    |> Enum.map(&normalize_integer/1)
    |> Enum.reject(&match?({_keys, nil}, &1))
    |> Enum.map(&normalize_row_callback.(&1))
    |> Enum.reject(&match?({_keys, nil}, &1))
    |> Enum.map(fn {keys, value} ->
      {Enum.map(keys, &Access.key(&1, %{})), value}
    end)
    |> Enum.reduce(%{}, fn {keys, value_new}, acc ->
      update_in(acc, keys, fn
        value_old when value_old == %{} ->
          value_new

        value_old when is_binary(value_old) and is_binary(value_new) ->
          value_old <> " / " <> value_new

        _value_old ->
          value_new
      end)
    end)
  end

  defp normalize_key(key),
    do: key |> String.downcase() |> String.replace(~R/[^\w]+/, "", global: true)

  defp add_headers(row, false) do
    {[], row}
  end

  defp add_headers(row, headers) do
    {[Enum.zip(headers, row)], headers}
  end

  defp normalize_date({key, {year, month, day}}) do
    case Date.new(year, month, day) do
      {:ok, date} -> {key, date}
      {:error, _reason} -> {key, nil}
    end
  end

  defp normalize_date(field), do: field

  defp normalize_integer({key, value}) when is_integer(value), do: {key, Integer.to_string(value)}
  defp normalize_integer(field), do: field

  defp accepted_mime_types, do: [@mime_type_csv, @mime_type_xlsx]
end
