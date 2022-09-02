defmodule HygeiaWeb.OrganisationLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Division
  alias Hygeia.OrganisationContext.Organisation
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  # Changeset or actual Tenant
  prop organisation, :map, required: true

  prop auth, :map, from_context: {HygeiaWeb, :auth}

  data display_name, :string

  @impl Phoenix.LiveComponent
  def update(
        %{organisation: %Changeset{data: data} = changeset} = _assigns,
        socket
      ) do
    {:ok,
     assign(socket,
       display_name: diplay_name(changeset),
       organisation: data
     )}
  end

  def update(%{organisation: %Organisation{} = organisation} = _assigns, socket) do
    {:ok,
     assign(socket,
       display_name: organisation.name,
       organisation: organisation
     )}
  end

  defp diplay_name(%Changeset{} = changeset),
    do: Changeset.get_field(changeset, :name)
end
