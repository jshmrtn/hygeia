defmodule HygeiaWeb.MutationLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.MutationContext
  alias Hygeia.MutationContext.Mutation
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.NumberInput
  alias Surface.Components.Form.TextInput

  data changeset, :map, default: nil
  data popup, :boolean, default: false

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Mutation, :create, get_auth(socket)) do
        assign(socket,
          changeset: MutationContext.change_mutation(%Mutation{}),
          page_title: gettext("New Mutation")
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"mutation" => mutation_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       MutationContext.change_mutation(%Mutation{}, mutation_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"mutation" => mutation_params}, socket) do
    mutation_params
    |> MutationContext.create_mutation()
    |> case do
      {:ok, mutation} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Mutation created successfully"))
         |> push_redirect(to: Routes.mutation_show_path(socket, :show, mutation))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
