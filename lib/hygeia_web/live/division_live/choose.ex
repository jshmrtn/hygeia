defmodule HygeiaWeb.DivisionLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Hygeia.OrganisationContext
  alias Hygeia.Repo
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @doc "An identifier for the form"
  prop form, :form

  @doc "An identifier for the associated field"
  prop field, :atom

  prop change, :event

  prop disabled, :boolean, default: false

  prop subject, :any, default: nil

  @doc "Value to pre-populated the input"
  prop value, :string

  prop organisation, :string, required: true

  data divisions, :list, default: []
  data modal_open, :boolean, default: false
  data query, :string, default: nil

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket),
    do: {:noreply, socket |> assign(modal_open: true) |> load_divisions()}

  def handle_event("close_modal", _params, socket),
    do: {:noreply, assign(socket, modal_open: false)}

  def handle_event("query", %{"value" => value} = _params, socket),
    do:
      {:noreply,
       socket
       |> assign(query: value)
       |> load_divisions}

  def handle_event(
        "received_post_message",
        %{"payload" => %{"event" => "created_division", "uuid" => uuid}},
        socket
      ),
      do:
        {:noreply,
         socket
         |> assign(query: uuid)
         |> load_divisions}

  def handle_event("received_post_message", _params, socket), do: {:noreply, socket}

  defp load_divisions(socket) do
    query =
      if socket.assigns.query in [nil, ""] do
        OrganisationContext.list_divisions_query(socket.assigns.organisation.uuid)
      else
        OrganisationContext.fulltext_division_search_query(
          socket.assigns.organisation.uuid,
          socket.assigns.query
        )
      end

    divisions =
      Repo.all(
        from(division in query,
          limit: 25
        )
      )

    assign(socket, divisions: divisions)
  end

  defp load_division(uuid), do: OrganisationContext.get_division!(uuid)

  defp render_division(assigns, division) do
    ~F"""
    <div>
      {division.title}
      <small class="d-block text-muted">{division.description}</small>
      <small class="d-block text-muted">{format_address(if division.shares_address, do: @organisation.address, else: division.address)}</small>
    </div>
    """
  end
end
