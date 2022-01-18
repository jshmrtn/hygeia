defmodule HygeiaWeb.DivisionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.OrganisationContext
  alias Hygeia.OrganisationContext.Division
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  data organisation, :map
  data changeset, :map
  data popup, :boolean, default: false

  @impl Phoenix.LiveView
  def mount(%{"organisation_id" => organisation_id} = params, _session, socket) do
    organisation = OrganisationContext.get_organisation!(organisation_id)

    socket =
      if authorized?(Division, :create, get_auth(socket), organisation: organisation) do
        assign(socket,
          organisation: organisation,
          changeset: OrganisationContext.change_new_division(organisation),
          page_title: gettext("New Division for {organisation}", organisation: organisation.name)
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    socket = if Map.has_key?(params, "popup"), do: assign(socket, popup: true), else: socket

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"division" => division_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       OrganisationContext.change_new_division(socket.assigns.organisation, division_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"division" => division_params}, socket) do
    socket.assigns.organisation
    |> OrganisationContext.create_division(division_params)
    |> case do
      {:ok, %Division{uuid: uuid} = division} ->
        if socket.assigns.popup do
          {:noreply,
           socket
           |> push_event("send_opener_post_messsage", %{event: "created_division", uuid: uuid})
           |> push_event("close_window", %{})}
        else
          {:noreply,
           socket
           |> put_flash(:info, gettext("Division created successfully"))
           |> push_redirect(to: Routes.division_show_path(socket, :show, division))}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
