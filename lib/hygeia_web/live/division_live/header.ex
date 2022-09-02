defmodule HygeiaWeb.DivisionLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.Repo
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  # Changeset or actual Tenant
  prop division, :map, required: true

  prop auth, :map, from_context: {HygeiaWeb, :auth}

  data display_name, :string

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do:
      preload_assigns_one(
        assign_list,
        :division,
        &Repo.preload(&1, :organisation),
        & &1.uuid,
        &(match?(%Changeset{}, &1) or is_nil(&1))
      )

  @impl Phoenix.LiveComponent
  def update(
        %{division: %Changeset{data: data} = changeset} = _assigns,
        socket
      ) do
    {:ok,
     assign(socket,
       display_name: diplay_name(changeset),
       division: data
     )}
  end

  def update(%{division: %Division{} = division} = _assigns, socket) do
    {:ok,
     assign(socket,
       display_name: division.title,
       division: division
     )}
  end

  defp diplay_name(%Changeset{} = changeset),
    do: Changeset.get_field(changeset, :title)
end
