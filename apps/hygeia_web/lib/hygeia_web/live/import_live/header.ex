# credo:disable-for-this-file Credo.Check.Readability.StrictModuleLayout
defmodule HygeiaWeb.ImportLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.ImportContext.Import
  alias Hygeia.ImportContext.Import.Type
  alias Hygeia.ImportContext.Row
  alias Hygeia.Repo
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  prop import, :map, required: true

  data counts, :map

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    extra_assigns =
      if assigns.import do
        %{
          counts: %{
            pending: Repo.aggregate(Ecto.assoc(assigns.import, :pending_rows), :count),
            resolved: Repo.aggregate(Ecto.assoc(assigns.import, :resolved_rows), :count),
            discarded: Repo.aggregate(Ecto.assoc(assigns.import, :discarded_rows), :count)
          }
        }
      else
        %{}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(extra_assigns)}
  end
end
