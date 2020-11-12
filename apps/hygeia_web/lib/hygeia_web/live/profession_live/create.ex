defmodule HygeiaWeb.ProfessionLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession
  alias HygeiaWeb.FormError
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Profession, :create, get_auth(socket)) do
        assign(socket, changeset: CaseContext.change_profession(%Profession{}))
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"profession" => profession_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_profession(%Profession{}, profession_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"profession" => profession_params}, socket) do
    profession_params
    |> CaseContext.create_profession()
    |> case do
      {:ok, profession} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Profession created successfully"))
         |> push_redirect(to: Routes.profession_show_path(socket, :show, profession))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
