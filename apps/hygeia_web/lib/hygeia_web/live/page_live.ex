defmodule HygeiaWeb.PageLive do
  @moduledoc """
  Page Live View
  """

  use HygeiaWeb, :surface_view

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    unless is_nil(session["cldr_locale"]) do
      HygeiaWeb.Cldr.put_locale(session["cldr_locale"])
    end

    Process.send_after(self(), :tick, 10)

    {:ok, socket |> Surface.init() |> assign(query: "", results: %{}, time: DateTime.utc_now())}
  end

  @impl Phoenix.LiveView
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _query ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext(~S(No dependencies found matching "%{query}"), query: query)
         )
         |> assign(results: %{}, query: query)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 10)

    {:noreply, assign(socket, time: DateTime.utc_now())}
  end

  defp search(query) do
    if not HygeiaWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
