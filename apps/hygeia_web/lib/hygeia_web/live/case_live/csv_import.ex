defmodule HygeiaWeb.CaseLive.CSVImport do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  prop mapping, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, file: nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{data: data} = assigns, socket) do
    extract_data(data, assigns[:mapping] || socket.assigns.mapping)

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

  defp extract_data(data, mapping) do
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
      |> Stream.map(&normalize_row(&1, mapping))

    send(self(), {:csv_import, {:ok, normalized_rows}})
  rescue
    e in FunctionClauseError -> send(self(), {:csv_import, {:error, e}})
  end

  defp normalize_row(%{} = row, key_mapping) do
    row
    |> Enum.map(fn {key, value} -> {normalize_key(key), value} end)
    |> Enum.filter(fn {key, _value} -> Map.has_key?(key_mapping, key) end)
    |> Enum.map(fn {key, value} -> {key_mapping[key], value} end)
    |> Map.new()
  end

  defp normalize_key(key),
    do: key |> String.downcase() |> String.replace(~R/[^\w]+/, "", global: true)
end
