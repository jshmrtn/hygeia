defmodule HygeiaWeb.CaseLive.Show do
  @moduledoc false

  use HygeiaWeb, :live_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.Helpers.Versioning
  alias Hygeia.Repo

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    unless is_nil(session["cldr_locale"]) do
      HygeiaWeb.Cldr.put_locale(session["cldr_locale"])
    end

    # TODO: Replace with correct Origin / Originator
    Versioning.put_origin(:web)
    Versioning.put_originator(:noone)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

    case = CaseContext.get_case!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :case,
       Repo.preload(
         case,
         person: [],
         received_transmissions: [propagator_case: [person: []]],
         propagated_transmissions: [recipient_case: [person: []]]
       )
     )
     |> assign(:versions, PaperTrail.get_versions(case))}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply,
     assign(
       socket,
       :case,
       Repo.preload(
         case,
         person: [],
         received_transmissions: [propagator_case: [person: []]],
         propagated_transmissions: [recipient_case: [person: []]]
       )
     )}
  end

  @impl Phoenix.LiveView
  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  defp page_title(:show), do: gettext("Show Case")
  defp page_title(:edit), do: gettext("Edit Case")
end
