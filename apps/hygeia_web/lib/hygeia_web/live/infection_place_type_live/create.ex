defmodule HygeiaWeb.InfectionPlaceTypeLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.InfectionPlaceType
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(InfectionPlaceType, :create, get_auth(socket)) do
        assign(socket, changeset: CaseContext.change_infection_place_type(%InfectionPlaceType{}))
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"infection_place_type" => infection_place_type_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_infection_place_type(%InfectionPlaceType{}, infection_place_type_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"infection_place_type" => infection_place_type_params}, socket) do
    infection_place_type_params
    |> CaseContext.create_infection_place_type()
    |> case do
      {:ok, infection_place_type} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Infection place type created successfully"))
         |> push_redirect(
           to: Routes.infection_place_type_show_path(socket, :show, infection_place_type)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
