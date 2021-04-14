defmodule HygeiaWeb.CaseLive.Transmissions do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.Repo
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(
           case,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

        load_data(socket, case)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply, load_data(socket, case)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(:reload, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info({:put_flash, type, msg}, socket), do: {:noreply, put_flash(socket, type, msg)}

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, case) do
    case =
      Repo.preload(
        case,
        received_transmissions: [propagator_case: [tenant: []], propagator: [tenant: []]],
        propagated_transmissions: [recipient_case: [tenant: []], recipient: [tenant: []]],
        person: [tenant: []],
        tenant: []
      )

    assign(socket,
      case: case,
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Transmissions")} - #{
          gettext("Case")
        }"
    )
  end
end
