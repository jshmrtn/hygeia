defmodule HygeiaWeb.ProfessionLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :live_component

  alias Hygeia.CaseContext

  @impl Phoenix.LiveComponent
  def update(%{profession: profession} = assigns, socket) do
    changeset = CaseContext.change_profession(profession)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"profession" => profession_params}, socket) do
    changeset =
      socket.assigns.profession
      |> CaseContext.change_profession(profession_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"profession" => profession_params}, socket) do
    save_profession(socket, socket.assigns.action, profession_params)
  end

  defp save_profession(socket, :edit, profession_params) do
    case CaseContext.update_profession(socket.assigns.profession, profession_params) do
      {:ok, _profession} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profession updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_profession(socket, :new, profession_params) do
    case CaseContext.create_profession(profession_params) do
      {:ok, _profession} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profession created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
