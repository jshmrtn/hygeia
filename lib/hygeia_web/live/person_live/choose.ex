defmodule HygeiaWeb.PersonLive.Choose do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Query

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Phoenix.HTML.FormData
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Link

  @doc "An identifier for the form"
  prop form, :form, from_context: {Form, :form}

  @doc "An identifier for the associated field"
  prop field, :atom, from_context: {Field, :field}

  prop change, :event

  prop disabled, :boolean, default: false
  prop discard_anonymized, :boolean, default: true
  prop small, :boolean, default: false

  prop subject, :any, default: nil

  prop auth, :map, from_context: {HygeiaWeb, :auth}

  data current_value, :struct, default: nil

  data modal_open, :boolean, default: false
  data query, :string, default: ""
  data tenants, :list, default: nil
  data has_value, :boolean, default: false
  data person, :struct, default: nil

  @impl Phoenix.LiveComponent
  def render(assigns) do
    has_value =
      FormData.input_value(assigns.form.source, assigns.form, assigns.field) not in [
        nil,
        ""
      ]

    person =
      if has_value do
        assigns.form.source
        |> FormData.input_value(assigns.form, assigns.field)
        |> load_person()
      end

    assigns
    |> assign(has_value: has_value, person: person)
    |> render_sface()
  end

  @impl Phoenix.LiveComponent
  def handle_event("open_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(
       modal_open: true,
       tenants:
         case socket.assigns.tenants do
           nil ->
             Enum.filter(
               TenantContext.list_tenants(),
               &authorized?(Person, :list, get_auth(socket), tenant: &1)
             )

           list when is_list(list) ->
             list
         end
     )
     |> load_people()}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, modal_open: false)}
  end

  def handle_event("query", %{"value" => value} = _params, socket) do
    socket =
      socket
      |> assign(query: value)
      |> load_people

    {:noreply, socket}
  end

  defp load_people(socket) do
    query =
      if socket.assigns.query in [nil, ""] do
        Person
      else
        CaseContext.fulltext_person_search_query(socket.assigns.query)
      end

    people =
      from(person in query,
        where: person.tenant_uuid in ^Enum.map(socket.assigns.tenants, & &1.uuid),
        limit: 25
      )
      |> maybe_discard_anonymized(socket.assigns.discard_anonymized)
      |> Repo.all()

    assign(socket, people: people)
  end

  defp load_person(uuid), do: uuid |> CaseContext.get_person!() |> Repo.preload(:tenant)

  defp format_date(nil), do: nil
  defp format_date(date), do: HygeiaCldr.Date.to_string!(date)

  defp maybe_discard_anonymized(query, true), do: where(query, [person], not person.anonymized)
  defp maybe_discard_anonymized(query, _any), do: query
end
