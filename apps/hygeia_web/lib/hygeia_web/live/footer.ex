defmodule HygeiaWeb.Footer do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.Helpers.Tenant, as: TenantHelper
  alias Phoenix.LiveView.Socket
  alias Surface.Components.Link

  prop tenant, :map
  prop tenants, :list
  prop case, :map
  prop auto_tracing, :map
  prop person, :map

  data subject, :map

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do:
      assign_list
      |> preload_assigns_one(:case, &Repo.preload(&1, tenant: []))
      |> preload_assigns_one(:auto_tracing, &Repo.preload(&1, case: [tenant: []]))
      |> preload_assigns_one(:person, &Repo.preload(&1, tenant: []))

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:subject, nil)
     |> assign(assigns)
     |> ensure_data_exists()}
  end

  defp ensure_data_exists(%Socket{assigns: %{tenants: nil}} = socket) do
    socket
    |> assign(
      tenants: Enum.filter(TenantContext.list_tenants(), &Tenant.is_internal_managed_tenant?/1)
    )
    |> ensure_data_exists()
  end

  defp ensure_data_exists(%Socket{assigns: %{subject: nil, tenant: %Tenant{} = tenant}} = socket) do
    socket
    |> assign(subject: tenant)
    |> ensure_data_exists()
  end

  defp ensure_data_exists(%Socket{assigns: %{subject: nil, case: %Case{tenant: tenant}}} = socket) do
    socket
    |> assign(subject: tenant)
    |> ensure_data_exists()
  end

  defp ensure_data_exists(
         %Socket{
           assigns: %{subject: nil, auto_tracing: %AutoTracing{case: %Case{tenant: tenant}}}
         } = socket
       ) do
    socket
    |> assign(subject: tenant)
    |> ensure_data_exists()
  end

  defp ensure_data_exists(
         %Socket{assigns: %{subject: nil, person: %Person{tenant: tenant}}} = socket
       ) do
    socket
    |> assign(subject: tenant)
    |> ensure_data_exists()
  end

  defp ensure_data_exists(socket), do: socket
end
