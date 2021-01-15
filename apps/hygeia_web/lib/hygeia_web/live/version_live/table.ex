defmodule HygeiaWeb.VersionLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.Repo
  alias PaperTrail.Version
  alias Surface.Components.LiveRedirect

  prop versions, :list, required: true
  prop now, :map, required: true

  @impl Phoenix.LiveComponent
  def preload(assigns_list) do
    assigns_list
    |> preload_assigns_many(:versions, &Repo.preload(&1, :user), & &1.id)
    |> Enum.map(fn
      %{versions: versions} = assigns ->
        %{assigns | versions: Enum.reject(versions, &(map_size(&1.item_changes) == 0))}

      other ->
        other
    end)
  end

  defp event_name("update"), do: pgettext("versioning_event", "update")
  defp event_name("insert"), do: pgettext("versioning_event", "insert")
  defp event_name("delete"), do: pgettext("versioning_event", "delete")
end
