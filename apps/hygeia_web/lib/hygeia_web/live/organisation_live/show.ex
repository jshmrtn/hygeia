defmodule HygeiaWeb.OrganisationLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Position
  alias Hygeia.Repo
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    organisation = OrganisationContext.get_organisation!(id)

    socket =
      if authorized?(
           organisation,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "organisations:#{id}")

        load_data(socket, organisation)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Organisation{} = organisation, _version}, socket) do
    {:noreply, assign(socket, :organisation, organisation)}
  end

  def handle_info({:deleted, %Organisation{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.organisation_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    organisation = OrganisationContext.get_organisation!(socket.assigns.organisation.uuid)

    {:noreply,
     socket
     |> load_data(organisation)
     |> push_patch(to: Routes.organisation_show_path(socket, :show, organisation))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    organisation_params = Map.put_new(organisation_params, "positions", [])

    {:noreply,
     socket
     |> assign(
       changeset: %{
         OrganisationContext.change_organisation(socket.assigns.organisation, organisation_params)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.organisation, :delete, get_auth(socket))

    {:ok, _} = OrganisationContext.delete_organisation(socket.assigns.organisation)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Organisation deleted successfully"))
     |> redirect(to: Routes.organisation_index_path(socket, :index))}
  end

  def handle_event("save", %{"organisation" => organisation_params}, socket) do
    true = authorized?(socket.assigns.organisation, :update, get_auth(socket))

    socket.assigns.organisation
    |> OrganisationContext.update_organisation(organisation_params)
    |> case do
      {:ok, organisation} ->
        {:noreply,
         socket
         |> load_data(organisation)
         |> put_flash(:info, gettext("Organisation updated successfully"))
         |> push_patch(to: Routes.organisation_show_path(socket, :show, organisation))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  def handle_event("remove_position", %{"uuid" => position_uuid}, socket) do
    {:noreply,
     assign(socket,
       changeset:
         Ecto.Changeset.put_assoc(
           socket.assigns.changeset,
           :positions,
           socket.assigns.changeset
           |> Ecto.Changeset.get_change(
             :positions,
             socket.assigns.changeset
             |> Ecto.Changeset.get_field(:positions, [])
             |> Enum.map(&OrganisationContext.change_position/1)
           )
           |> Enum.reject(&(Ecto.Changeset.get_field(&1, :uuid) == position_uuid))
         )
     )}
  end

  def handle_event("add_position", _params, socket) do
    {:noreply,
     assign(socket,
       changeset:
         Ecto.Changeset.put_assoc(
           socket.assigns.changeset,
           :positions,
           socket.assigns.changeset
           |> Ecto.Changeset.get_change(
             :positions,
             socket.assigns.changeset
             |> Ecto.Changeset.get_field(:positions, [])
             |> Enum.map(&OrganisationContext.change_position/1)
           )
           |> Kernel.++([
             OrganisationContext.change_position(%Position{
               organisation_uuid: socket.assigns.organisation.uuid
             })
           ])
         )
     )}
  end

  defp load_data(socket, organisation) do
    organisation = Repo.preload(organisation, positions: [:person])
    changeset = OrganisationContext.change_organisation(organisation)

    socket
    |> assign(
      organisation: organisation,
      changeset: changeset,
      people: CaseContext.list_people(),
      versions: PaperTrail.get_versions(organisation)
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

  defp person_display_name(%Person{last_name: nil, first_name: first_name} = _person) do
    first_name
  end

  defp person_display_name(%Person{last_name: last_name, first_name: first_name} = _person) do
    "#{first_name} #{last_name}"
  end
end
