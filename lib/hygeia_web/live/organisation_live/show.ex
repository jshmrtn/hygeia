defmodule HygeiaWeb.OrganisationLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.Helpers.Empty
  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.OrganisationContext.Organisation.SchoolType
  alias Hygeia.OrganisationContext.Organisation.Type
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.LiveRedirect

  data duplicate_organisations, :list, default: []

  @impl Phoenix.LiveView
  def render(assigns) do
    assigns
    |> assign(
      duplicate_organisations:
        assigns.changeset
        |> Ecto.Changeset.fetch_field!(:suspected_duplicates_uuid)
        |> OrganisationContext.list_organisations_by_ids()
    )
    |> render_sface()
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
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
        socket = assign(socket, page_title: "#{organisation.name} - #{gettext("Organisation")}")
        load_data(socket, organisation)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
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

  defp load_data(socket, organisation) do
    changeset = OrganisationContext.change_organisation(organisation)

    socket
    |> assign(organisation: organisation, changeset: changeset)
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
    if Empty.is_empty?(changeset, [:suspected_duplicates_uuid]) do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
