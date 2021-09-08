defmodule HygeiaWeb.RowLive.ApplyNextPending do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.ImportContext
  alias Hygeia.ImportContext.Import
  alias Hygeia.Repo

  @impl Phoenix.LiveView
  def handle_params(%{"import_id" => id}, _uri, socket) do
    {:noreply,
     id
     |> ImportContext.get_import!()
     |> Repo.preload(pending_rows: [])
     |> case do
       %Import{pending_rows: [next_row | _others]} ->
         push_redirect(socket, to: Routes.row_apply_path(socket, :apply, next_row))

       %Import{pending_rows: []} = import ->
         push_redirect(socket, to: Routes.import_show_path(socket, :show, import))
     end}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~F"""
    <span>{gettext("Redirecting")}</span>
    """
  end
end
