defmodule HygeiaWeb.PersonLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias HygeiaWeb.FormError

  alias Surface.Components.Form
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{id}")

    person = CaseContext.get_person!(id)

    tenants = TenantContext.list_tenants()
    professions = CaseContext.list_professions()

    {:noreply, socket |> assign(tenants: tenants, professions: professions) |> load_data(person)}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Person{} = person, _version}, socket) do
    {:noreply, load_data(socket, person)}
  end

  def handle_info({:deleted, %Person{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.person_index_path(socket, :index))}
  end

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    person = CaseContext.get_person!(socket.assigns.person.uuid)

    {:noreply,
     socket
     |> load_data(socket.assigns.person)
     |> push_patch(to: Routes.person_show_path(socket, :show, person))}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_person(socket.assigns.person, person_params)
       | action: :validate
     })}
  end

  def handle_event("add_contact_method", _params, socket) do
    contact_methods = Ecto.Changeset.get_field(socket.assigns.changeset, :contact_methods, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :contact_methods,
        contact_methods ++ [%{}]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_external_reference", _params, socket) do
    external_references =
      Ecto.Changeset.get_field(socket.assigns.changeset, :external_references, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :external_references,
        external_references ++ [%{}]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("add_employer", _params, socket) do
    employers = Ecto.Changeset.get_field(socket.assigns.changeset, :employers, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :employers,
        employers ++ [%{}]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    socket.assigns.person
    |> CaseContext.update_person(person_params)
    |> case do
      {:ok, person} ->
        {:noreply,
         socket
         |> load_data(person)
         |> put_flash(:info, gettext("Person updated successfully"))
         |> push_patch(to: Routes.person_show_path(socket, :show, person))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, positions: [organisation: []])

    changeset = CaseContext.change_person(person)

    assign(
      socket,
      person: person,
      changeset: changeset,
      versions: PaperTrail.get_versions(person)
    )
  end
end
