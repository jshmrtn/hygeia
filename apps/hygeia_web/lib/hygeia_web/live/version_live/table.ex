defmodule HygeiaWeb.VersionLive.Table do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.Repo
  alias PaperTrail.Version
  alias Surface.Components.LiveRedirect

  prop versions, :list, required: true
  prop now, :map, required: true

  @impl Phoenix.LiveComponent
  def preload(assign_list) do
    all_version_preloaded =
      assign_list
      |> Enum.flat_map(&(&1[:versions] || []))
      |> Enum.uniq_by(& &1.id)
      |> Repo.preload(:user)
      |> Map.new(&{&1.id, &1})

    Enum.map(assign_list, fn
      %{versions: versions} = assigns ->
        %{
          assigns
          | versions:
              versions
              |> Enum.map(&Map.fetch!(all_version_preloaded, &1.id))
              |> Enum.reject(&(map_size(&1.item_changes) == 0))
        }

      other ->
        other
    end)
  end

  defp event_name("update"), do: pgettext("versioning_event", "update")
  defp event_name("insert"), do: pgettext("versioning_event", "insert")
  defp event_name("delete"), do: pgettext("versioning_event", "delete")
end
