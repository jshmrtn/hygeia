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
    {:ok,
     allow_upload(socket, :list,
       accept: ~w(.csv .xlsx),
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl Phoenix.LiveComponent

  def handle_event("import", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("show_help", _params, socket) do
    {:noreply, assign(socket, show_help: true)}
  end

  def handle_event("hide_help", _params, socket) do
    {:noreply, assign(socket, show_help: false)}
  end

  defp handle_progress(
         :list,
         %Phoenix.LiveView.UploadEntry{done?: true, client_type: mime, client_name: client_name} =
           entry,
         socket
       ) do
    result =
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        new_path = Briefly.create!(extname: client_name)
        File.cp!(path, new_path)

        extract_data(
          new_path,
          Map.fetch!(%{@mime_type_csv => :csv, @mime_type_xlsx => :xlsx}, mime),
          socket.assigns.mapping
          |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
          |> Enum.uniq()
          |> Map.new(),
          socket.assigns.normalize_row_callback
        )
      end)

    send(self(), {:csv_import, {:ok, result}})

    {:noreply, socket}
  end

  defp handle_progress(:list, _entry, socket), do: {:noreply, socket}

  defp extract_data(path, :csv, mapping, normalize_row_callback) do
    path
    |> File.stream!()
    |> Stream.reject(&match?("", &1))
    |> CSV.decode!(headers: true)
    |> Stream.map(&normalize_row(&1, mapping, normalize_row_callback))
    |> Enum.to_list()
  end

  defp extract_data(path, :xlsx, mapping, normalize_row_callback) do
    path
    |> Xlsxir.stream_list(0)
    |> Stream.transform(false, &add_headers/2)
    |> Stream.map(&normalize_row(&1, mapping, normalize_row_callback))
    |> Enum.to_list()
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
end
