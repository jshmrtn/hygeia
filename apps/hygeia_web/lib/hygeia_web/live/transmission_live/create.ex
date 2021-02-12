defmodule HygeiaWeb.TransmissionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Transmission
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Transmission, :create, get_auth(socket)) do
        assign(socket, changeset: CaseContext.change_transmission(%Transmission{}, params))
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("validate", %{"transmission" => transmission_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_transmission(%Transmission{}, transmission_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"transmission" => transmission_params}, socket) do
    transmission_params
    |> CaseContext.create_transmission()
    |> case do
      {:ok, transmission} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Transmission created successfully"))
         |> push_redirect(to: Routes.transmission_show_path(socket, :show, transmission))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("change_propagator_case", params, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_transmission(
         %Transmission{},
         Map.put(socket.assigns.changeset.params, "propagator_case_uuid", params["uuid"])
       )
       | action: :validate
     })}
  end

  def handle_event("change_recipient_case", params, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_transmission(
         %Transmission{},
         Map.put(socket.assigns.changeset.params, "recipient_case_uuid", params["uuid"])
       )
       | action: :validate
     })}
  end
end
