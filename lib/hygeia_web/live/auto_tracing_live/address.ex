defmodule HygeiaWeb.AutoTracingLive.Address do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.AutoTracing, only: [get_next_step_route: 1]

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Monitoring.IsolationLocation
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field

  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.LiveRedirect

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(tenant: [], person: [], auto_tracing: [])

    socket =
      cond do
        Case.closed?(case) ->
          raise HygeiaWeb.AutoTracingLive.AutoTracing.CaseClosedError, case_uuid: case.uuid

        !authorized?(case, :auto_tracing, get_auth(socket)) ->
          push_redirect(socket,
            to:
              Routes.auth_login_path(socket, :login,
                person_uuid: case.person_uuid,
                return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
              )
          )

        !AutoTracing.step_available?(case.auto_tracing, :address) ->
          push_redirect(socket,
            to: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
          )

        true ->
          assign(socket,
            case: case,
            case_changeset: %Ecto.Changeset{CaseContext.change_case(case) | action: :validate},
            person: case.person,
            person_changeset: %Ecto.Changeset{
              CaseContext.change_person(
                case.person,
                %{address: %{subdivision: case.tenant.subdivision, country: case.tenant.country}},
                %{address_required: true}
              )
              | action: :validate
            },
            auto_tracing: case.auto_tracing
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
      assign(socket, :person_changeset, %Ecto.Changeset{
        CaseContext.change_person(socket.assigns.person, %{address: address}, %{
          address_required: true
        })
        | action: :validate
      })

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"case" => %{"monitoring" => monitoring}},
        socket
      ) do
    socket =
      assign(socket, :case_changeset, %Ecto.Changeset{
        CaseContext.change_case(socket.assigns.case, %{monitoring: monitoring})
        | action: :validate
      })

    {:noreply, socket}
  end

  def handle_event("advance", _params, socket) do
    {:ok, case} =
      CaseContext.update_case(%Ecto.Changeset{socket.assigns.case_changeset | action: nil})

    {:ok, person} =
      CaseContext.update_person(
        %Ecto.Changeset{socket.assigns.person_changeset | action: nil},
        %{},
        %{address_required: true}
      )

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

    auto_tracing =
      case {person.address, detect_tenant(person.address), detect_tenant(isolation_address)} do
        {_person_address, {true, redidency_tenant},
         {_isolation_tenant_internal, _isolation_tenant}} ->
          {:ok, _case} = CaseContext.update_case(case, %{tenant_uuid: redidency_tenant.uuid})

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_remove_problem(
              socket.assigns.auto_tracing,
              :unmanaged_tenant
            )

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_remove_problem(
              auto_tracing,
              :residency_outside_country
            )

          auto_tracing

        {%Address{country: country}, {false, nil}, {true, isolation_tenant}}
        when country != "CH" ->
          {:ok, _case} = CaseContext.update_case(case, %{tenant_uuid: isolation_tenant.uuid})

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_remove_problem(
              socket.assigns.auto_tracing,
              :unmanaged_tenant
            )

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_add_problem(
              auto_tracing,
              :residency_outside_country
            )

          auto_tracing

        {_person_address, {false, %Tenant{} = residency_tenant},
         {_isolation_tenant_internal, _isolation_tenant}} ->
          {:ok, _case} = CaseContext.update_case(case, %{tenant_uuid: residency_tenant.uuid})

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_add_problem(
              socket.assigns.auto_tracing,
              :unmanaged_tenant
            )

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_remove_problem(
              auto_tracing,
              :residency_outside_country
            )

          auto_tracing

        {_person_address, {false, nil}, {_isolation_tenant_internal, _isolation_tenant}} ->
          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_add_problem(
              socket.assigns.auto_tracing,
              :unmanaged_tenant
            )

          {:ok, auto_tracing} =
            AutoTracingContext.auto_tracing_remove_problem(
              auto_tracing,
              :residency_outside_country
            )

          auto_tracing
      end

    socket = assign(socket, auto_tracing: auto_tracing)

    if AutoTracing.has_problem?(auto_tracing, :unmanaged_tenant) do
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
         to: get_next_step_route(:address).(socket, socket.assigns.auto_tracing.case_uuid)
       )}
    end
  end

  defp detect_tenant(nil), do: {false, nil}

  defp detect_tenant(%Address{country: country, subdivision: subdivision}) do
    case TenantContext.get_tenant_by_region(%{
           country: country,
           subdivision: subdivision
         }) do
      nil ->
        {false, nil}

      %TenantContext.Tenant{} = tenant ->
        {TenantContext.Tenant.is_internal_managed_tenant?(tenant), tenant}
    end
  end
end
