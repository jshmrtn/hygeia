defmodule HygeiaWeb.TransmissionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.Repo
  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, _uri, socket) do
    transmission = CaseContext.get_transmission!(id)

    socket =
      if params["return_url"] do
        assign(socket, return_url: params["return_url"])
      else
        socket
      end

    socket =
      if authorized?(
           transmission,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "transmission:#{id}")

        load_data(socket, transmission, params)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Transmission{} = transmission, _version}, socket) do
    {:noreply, load_data(socket, transmission)}
  end

  def handle_info({:deleted, %Transmission{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    transmission = CaseContext.get_transmission!(socket.assigns.transmission.uuid)

    {:noreply,
     socket
     |> load_data(transmission)
     |> push_patch(to: Routes.transmission_show_path(socket, :show, transmission))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"transmission" => transmission_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         CaseContext.change_transmission(socket.assigns.transmission, transmission_params)
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.transmission, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_transmission(socket.assigns.transmission)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Transmission deleted successfully"))
     |> redirect(to: Routes.case_index_path(socket, :index))}
  end

  def handle_event("save", %{"transmission" => transmission_params}, socket) do
    true = authorized?(socket.assigns.transmission, :update, get_auth(socket))

    socket.assigns.transmission
    |> CaseContext.update_transmission(transmission_params)
    |> case do
      {:ok, transmission} ->
        {:noreply,
         socket
         |> load_data(transmission)
         |> put_flash(:info, gettext("Transmission updated successfully"))
         |> case do
           %Socket{assigns: %{return_url: return_url}} = socket ->
             push_redirect(socket, to: return_url)

           socket ->
             push_patch(socket, to: Routes.transmission_show_path(socket, :show, transmission))
         end}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  def handle_event("change_propagator_case", params, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_transmission(
         socket.assigns.transmission,
         Map.put(socket.assigns.changeset.params, "propagator_case_uuid", params["uuid"])
       )
       | action: :validate
     })}
  end

  def handle_event("change_recipient_case", params, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_transmission(
         socket.assigns.transmission,
         Map.put(socket.assigns.changeset.params, "recipient_case_uuid", params["uuid"])
       )
       | action: :validate
     })}
  end

  defp load_data(socket, transmission, attrs \\ %{}) do
    transmission =
      Repo.preload(transmission,
        recipient: [tenant: []],
        recipient_case: [tenant: []],
        propagator: [tenant: []],
        propagator_case: [tenant: []]
      )

    changeset = CaseContext.change_transmission(transmission, attrs)

    socket
    |> assign(
      transmission: transmission,
      changeset: changeset,
      people: CaseContext.list_people(),
      page_title: gettext("Transmission")
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
