defmodule HygeiaWeb.HomeLive.Index do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    auth = get_auth(socket)

    cond do
      authorized?(Hygeia.CaseContext.Case, :list, auth, tenant: :any) ->
        {:ok, push_redirect(socket, to: Routes.case_index_path(socket, :index))}

      authorized?(Hygeia.CaseContext.Person, :list, auth, tenant: :any) ->
        {:ok, push_redirect(socket, to: Routes.person_index_path(socket, :index))}

      true ->
        {:ok, socket}
    end
  end
end
