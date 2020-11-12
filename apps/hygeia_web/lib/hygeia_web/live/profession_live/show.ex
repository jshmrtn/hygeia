defmodule HygeiaWeb.ProfessionLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    profession = CaseContext.get_profession!(id)

    socket =
      if authorized?(
           profession,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "professions:#{id}")

        load_data(socket, profession)
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Profession{} = profession}, socket) do
    {:noreply, assign(socket, :profession, profession)}
  end

  def handle_info({:deleted, %Profession{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.profession_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    profession = CaseContext.get_profession!(socket.assigns.profession.uuid)

    {:noreply,
     socket
     |> load_data(profession)
     |> push_patch(to: Routes.profession_show_path(socket, :show, profession))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"profession" => profession_params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_profession(socket.assigns.profession, profession_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.profession, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_profession(socket.assigns.profession)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Profession deleted successfully"))
     |> redirect(to: Routes.profession_index_path(socket, :index))}
  end

  def handle_event("save", %{"profession" => profession_params}, socket) do
    socket.assigns.profession
    |> CaseContext.update_profession(profession_params)
    |> case do
      {:ok, profession} ->
        {:noreply,
         socket
         |> load_data(profession)
         |> put_flash(:info, gettext("Profession updated successfully"))
         |> push_patch(to: Routes.profession_show_path(socket, :show, profession))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  defp load_data(socket, profession) do
    changeset = CaseContext.change_profession(profession)

    socket
    |> assign(
      profession: profession,
      changeset: changeset,
      versions: PaperTrail.get_versions(profession)
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
