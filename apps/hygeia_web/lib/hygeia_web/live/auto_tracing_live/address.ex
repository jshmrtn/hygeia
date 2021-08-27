defmodule HygeiaWeb.AutoTracingLive.Address do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Surface.Components.Form
  alias Surface.Components.Form.Inputs
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        assign(socket,
          case: case,
          case_changeset: CaseContext.change_case(case),
          person: case.person,
          person_changeset:
            CaseContext.change_person(case.person, %{}, %{address_required: true}),
          auto_tracing: case.auto_tracing
        )
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
            )
        )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"person" => %{"address" => address}},
        socket
      ) do
    socket =
      assign(socket, :person_changeset, %{
        CaseContext.change_person(socket.assigns.person, %{address: address}, %{
          address_required: true
        })
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"case" => %{"monitoring" => monitoring}},
        socket
      ) do
    socket =
      assign(socket, :case_changeset, %{
        CaseContext.change_case(socket.assigns.case, %{monitoring: monitoring})
        | action: :update
      })

    {:noreply, socket}
  end

  def handle_event("advance", _params, socket) do
    {:ok, case} = CaseContext.update_case(socket.assigns.case_changeset)

    {:ok, person} =
      CaseContext.update_person(socket.assigns.person_changeset, %{}, %{address_required: true})

    isolation_address =
      case case do
        %Case{
          monitoring: %Case.Monitoring{
            address: %Address{address: nil, zip: nil, place: nil, subdivision: nil}
          }
        } ->
          person.address

        %Case{monitoring: %Case.Monitoring{address: address}} ->
          address

        %Case{} ->
          person.address
      end

    unmanaged_tenant =
      case TenantContext.get_tenant_by_region(%{
             country: isolation_address.country,
             subdivision: isolation_address.subdivision
           }) do
        nil ->
          true

        %TenantContext.Tenant{} = tenant ->
          {:ok, _case} = CaseContext.update_case(case, %{tenant_uuid: tenant.uuid})

          not TenantContext.Tenant.is_internal_managed_tenant?(tenant)
      end

    {:ok, auto_tracing} =
      if unmanaged_tenant do
        AutoTracingContext.auto_tracing_add_problem(
          socket.assigns.auto_tracing,
          :unmanaged_tenant
        )
      else
        AutoTracingContext.auto_tracing_remove_problem(
          socket.assigns.auto_tracing,
          :unmanaged_tenant
        )
      end

    socket = assign(socket, auto_tracing: auto_tracing)

    if unmanaged_tenant do
      {:noreply,
       push_redirect(socket,
         to:
           Routes.auto_tracing_tenant_exit_path(
             socket,
             :tenant_exit,
             socket.assigns.auto_tracing.case_uuid
           )
       )}
    else
      {:ok, _auto_tracing} =
        AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :address)

      {:noreply,
       push_redirect(socket,
         to:
           Routes.auto_tracing_contact_methods_path(
             socket,
             :contact_methods,
             socket.assigns.auto_tracing.case_uuid
           )
       )}
    end
  end
end
