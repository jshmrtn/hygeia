defmodule HygeiaWeb.OrganisationLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Organisation
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  data changeset, :map, default: nil
  data popup, :boolean, default: false

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Organisation, :create, get_auth(socket)) do
        assign(socket, changeset: OrganisationContext.change_organisation(%Organisation{}))
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    socket = if Map.has_key?(params, "popup"), do: assign(socket, popup: true), else: socket

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       OrganisationContext.change_organisation(%Organisation{}, organisation_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"organisation" => organisation_params}, socket) do
    organisation_params
    |> OrganisationContext.create_organisation()
    |> case do
      {:ok, %Organisation{uuid: uuid} = organisation} ->
        if socket.assigns.popup do
          {:noreply,
           socket
           |> push_event("send_opener_post_messsage", %{event: "created_organisation", uuid: uuid})
           |> push_event("close_window", %{})}
        else
          {:noreply,
           socket
           |> put_flash(:info, gettext("Organisation created successfully"))
           |> push_redirect(to: Routes.organisation_show_path(socket, :show, organisation))}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
