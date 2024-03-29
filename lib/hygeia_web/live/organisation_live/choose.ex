defmodule HygeiaWeb.OrganisationLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Phoenix.HTML.FormData
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @doc "An identifier for the form"
  prop form, :form, from_context: {Form, :form}

  @doc "An identifier for the associated field"
  prop field, :atom, from_context: {Field, :field}

  prop change, :event

  prop disabled, :boolean, default: false

  prop subject, :any, default: nil

  @doc "Value to pre-populated the input"
  prop value, :string

  prop query_clauses, :list, default: []

  prop auth, :map, from_context: {HygeiaWeb, :auth}

  data modal_open, :boolean, default: false
  data query, :string, default: nil
  data organisation, :struct, default: nil

  @impl Phoenix.LiveComponent
  def mount(socket), do: {:ok, socket}

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> load_organisations()}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    value =
      assigns.value || FormData.input_value(assigns.form.source, assigns.form, assigns.field)

    has_value = value not in [nil, ""]

    organisation = if has_value, do: load_organisation(value)

    assigns
    |> assign(internal_value: value, has_value: has_value, organisation: organisation)
    |> render_sface()
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket),
    do: {:noreply, assign(socket, modal_open: true)}

  def handle_event("close_modal", _params, socket),
    do: {:noreply, assign(socket, modal_open: false)}

  def handle_event("query", %{"value" => value} = _params, socket),
    do:
      {:noreply,
       socket
       |> assign(query: value)
       |> load_organisations}

  def handle_event(
        "received_post_message",
        %{"payload" => %{"event" => "created_organisation", "uuid" => uuid}},
        socket
      ),
      do:
        {:noreply,
         socket
         |> assign(query: uuid)
         |> load_organisations}

  def handle_event("received_post_message", _params, socket), do: {:noreply, socket}

  defp load_organisations(socket) do
    query =
      if socket.assigns.query in [nil, ""] do
        OrganisationContext.list_organisations_query()
      else
        OrganisationContext.fulltext_organisation_search_query(socket.assigns.query)
      end

    organisations =
      socket.assigns.query_clauses
      |> Enum.reduce(query, fn clause, q ->
        clause.(q)
      end)
      |> Kernel.then(&from(organisation in &1, limit: 25))
      |> Repo.all()

    assign(socket, organisations: organisations)
  end

  defp load_organisation(uuid), do: OrganisationContext.get_organisation!(uuid)

  defp render_organisation(assigns, organisation) do
    ~F"""
    {organisation.name}
    <small class="d-block text-muted" :if={not is_nil(organisation.type)}>
      {Organisation.type_name(organisation)}
    </small>
    <small class="d-block text-muted">{format_address(organisation.address)}</small>
    """
  end
end
