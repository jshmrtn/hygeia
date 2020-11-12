defmodule HygeiaWeb.PersonLive.BaseData do
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
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    person = CaseContext.get_person!(id)

    socket =
      if authorized?(
           person,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "people:#{id}")

        tenants = TenantContext.list_tenants()
        professions = CaseContext.list_professions()

        socket |> assign(tenants: tenants, professions: professions) |> load_data(person)
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Person{} = person, _version}, socket) do
    {:noreply, load_data(socket, person)}
  end

  def handle_info({:deleted, %Person{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.person_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    person = CaseContext.get_person!(socket.assigns.person.uuid)

    {:noreply,
     socket
     |> load_data(socket.assigns.person)
     |> push_patch(to: Routes.person_base_data_path(socket, :show, person))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"person" => person_params}, socket) do
    person_params =
      person_params
      |> Map.put_new("employers", [])
      |> Map.put_new("contact_methods", [])
      |> Map.put_new("external_references", [])

    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_person(socket.assigns.person, person_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("add_contact_method", _params, socket) do
    contact_methods = Ecto.Changeset.get_field(socket.assigns.changeset, :contact_methods, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :contact_methods,
        contact_methods ++ [%{}]
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
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

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("add_employer", _params, socket) do
    employers = Ecto.Changeset.get_field(socket.assigns.changeset, :employers, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :employers,
        employers ++ [%{}]
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> maybe_block_navigation()}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    person_params =
      person_params
      |> Map.put_new("employers", [])
      |> Map.put_new("contact_methods", [])
      |> Map.put_new("external_references", [])

    socket.assigns.person
    |> CaseContext.update_person(person_params)
    |> case do
      {:ok, person} ->
        {:noreply,
         socket
         |> load_data(person)
         |> put_flash(:info, gettext("Person updated successfully"))
         |> push_patch(to: Routes.person_base_data_path(socket, :show, person))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, person) do
    person = Repo.preload(person, positions: [organisation: []])

    changeset = CaseContext.change_person(person)

    socket
    |> assign(
      person: person,
      changeset: changeset,
      versions: PaperTrail.get_versions(person)
    )
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
