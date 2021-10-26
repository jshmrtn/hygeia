defmodule HygeiaWeb.MutationLive.Show do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.MutationContext
  alias Hygeia.MutationContext.Mutation
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    mutation = MutationContext.get_mutation!(id)

    socket =
      if authorized?(
           mutation,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "mutations:#{id}")
        socket = assign(socket, page_title: "#{mutation.name} - #{gettext("Mutation")}")
        load_data(socket, mutation)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Mutation{} = mutation, _version}, socket) do
    {:noreply, assign(socket, :mutation, mutation)}
  end

  def handle_info({:deleted, %Mutation{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.mutation_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    mutation = MutationContext.get_mutation!(socket.assigns.mutation.uuid)

    {:noreply,
     socket
     |> load_data(mutation)
     |> push_patch(to: Routes.mutation_show_path(socket, :show, mutation))}
  end

  def handle_event("validate", %{"mutation" => mutation_params}, socket) do
    {:noreply,
     assign(socket,
       changeset: %{
         MutationContext.change_mutation(socket.assigns.mutation, mutation_params)
         | action: :validate
       }
     )}
  end

  def handle_event("delete", _params, socket) do
    true = authorized?(socket.assigns.mutation, :delete, get_auth(socket))

    {:ok, _} = MutationContext.delete_mutation(socket.assigns.mutation)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Mutation deleted successfully"))
     |> redirect(to: Routes.mutation_index_path(socket, :index))}
  end

  def handle_event("save", %{"mutation" => mutation_params}, socket) do
    true = authorized?(socket.assigns.mutation, :update, get_auth(socket))

    socket.assigns.mutation
    |> MutationContext.update_mutation(mutation_params)
    |> case do
      {:ok, mutation} ->
        {:noreply,
         socket
         |> load_data(mutation)
         |> put_flash(:info, gettext("Mutation updated successfully"))
         |> push_patch(to: Routes.mutation_show_path(socket, :show, mutation))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp load_data(socket, mutation) do
    changeset = MutationContext.change_mutation(mutation)

    assign(socket, mutation: mutation, changeset: changeset)
  end
end
