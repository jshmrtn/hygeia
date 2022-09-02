defmodule HygeiaWeb.MutationLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.MutationContext
  alias Hygeia.MutationContext.Mutation
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Mutation, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "mutations")

        assign(socket,
          page_title: gettext("Mutations"),
          mutations: MutationContext.list_mutations()
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    mutation = MutationContext.get_mutation!(id)

    true = authorized?(mutation, :delete, get_auth(socket))

    {:ok, _} = MutationContext.delete_mutation(mutation)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Mutation deleted successfully"))
     |> assign(mutations: MutationContext.list_mutations())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Mutation{}, _version}, socket) do
    {:noreply, assign(socket, mutations: MutationContext.list_mutations())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
