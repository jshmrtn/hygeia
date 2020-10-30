defmodule HygeiaWeb.CaseLive.Transmissions do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

    {:noreply, load_data(socket, id)}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Case{} = _case, _version}, socket) do
    {:noreply, load_data(socket, socket.assigns.case.id)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, id) do
    case =
      id
      |> CaseContext.get_case!()
      |> Repo.preload(
        received_transmissions: [propagator_case: [person: []]],
        propagated_transmissions: [recipient_case: [person: []]],
        person: []
      )

    assign(socket, case: case)
  end
end
