defmodule HygeiaWeb.ProfessionLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Profession
  alias Surface.Components.Context
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Profession, :list, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "professions")

        assign(socket, :professions, list_professions())
      else
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    profession = CaseContext.get_profession!(id)

    true = authorized?(profession, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_profession(profession)

    {:noreply, assign(socket, :professions, list_professions())}
  end

  @impl Phoenix.LiveView
  def handle_info({_type, %Profession{}, _version}, socket) do
    {:noreply, assign(socket, :professions, list_professions())}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp list_professions, do: CaseContext.list_professions()
end
