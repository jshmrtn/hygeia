defmodule HygeiaWeb.TenantLive.Header do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Ecto.Changeset
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.LiveRedirect

  # Changeset or actual Tenant
  prop tenant, :map, required: true

  data display_name, :string

  @impl Phoenix.LiveComponent
  def update(
        %{tenant: %Changeset{data: data} = changeset} = _assigns,
        socket
      ) do
    {:ok,
     assign(socket,
       display_name: tenant_display_name(changeset),
       tenant: data
     )}
  end

  def update(%{tenant: %Tenant{} = tenant} = _assigns, socket) do
    {:ok,
     assign(socket,
       display_name: tenant.name,
       tenant: tenant
     )}
  end

  defp tenant_display_name(%Changeset{} = changeset),
    do: Changeset.get_field(changeset, :name)
end
