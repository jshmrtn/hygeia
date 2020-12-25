defmodule HygeiaWeb.OrganisationLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :atom

  prop change, :event

  prop disabled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(modal_open: false, query: nil)
      |> load_organisations

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: false)}
  end

  def handle_event("query", %{"value" => value} = _params, socket) do
    socket =
      socket
      |> assign(query: value)
      |> load_organisations

    {:noreply, socket}
  end

  defp load_organisations(socket) do
    query =
      if socket.assigns.query in [nil, ""] do
        OrganisationContext.list_organisations_query()
      else
        OrganisationContext.fulltext_organisation_search_query(socket.assigns.query)
      end

    organisations =
      Repo.all(
        from(organisation in query,
          limit: 25
        )
      )

    assign(socket, organisations: organisations)
  end

  defp load_organisation(uuid), do: OrganisationContext.get_organisation!(uuid)
end
