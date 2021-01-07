defmodule HygeiaWeb.OrganisationLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.OrganisationContext.Organisation
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  # Changeset or actual Tenant
  prop organisation, :map, required: true

  data display_name, :string

  @impl Phoenix.LiveComponent
  def update(
        %{organisation: %Changeset{data: data} = changeset} = _assings,
        socket
      ) do
    {:ok,
     assign(socket,
       display_name: diplay_name(changeset),
       organisation: data
     )}
  end

  def update(%{organisation: %Organisation{} = organisation} = _assings, socket) do
    {:ok,
     assign(socket,
       display_name: organisation.name,
       organisation: organisation
     )}
  end

  defp diplay_name(%Changeset{} = changeset),
    do: Changeset.get_field(changeset, :name)
end
