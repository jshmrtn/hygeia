defmodule HygeiaWeb.CaseLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(Case, :create, get_auth(socket), tenant: :any) do
        assign(socket,
          changeset: CaseContext.change_case(%Case{}),
          page_title: gettext("New Case"),
          tenants:
            Enum.filter(
              TenantContext.list_tenants(),
              &authorized?(Case, :create, get_auth(socket), tenant: &1)
            )
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"case" => case_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_case(%Case{}, case_params)
       | action: :validate
     })}
  end

  def handle_event("change_person", params, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_case(
         %Case{},
         update_changeset_param(socket.assigns.changeset, :person_uuid, fn _before ->
           params["uuid"]
         end)
       )
       | action: :validate
     })}
  end

  def handle_event(
        "save",
        %{"case" => %{"tenant_uuid" => tenant_uuid, "person_uuid" => person_uuid} = case_params},
        %Phoenix.LiveView.Socket{assigns: %{tenants: tenants}} = socket
      ) do
    %Case{}
    |> CaseContext.change_case(case_params)
    |> Map.put(:action, :validate)
    |> case do
      %Ecto.Changeset{valid?: true} ->
        tenant = Enum.find(tenants, &match?(%Tenant{uuid: ^tenant_uuid}, &1))
        person = CaseContext.get_person!(person_uuid)

        person
        |> CaseContext.create_case(tenant, case_params)
        |> case do
          {:ok, case} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Case created successfully"))
             |> push_redirect(to: Routes.case_base_data_path(socket, :show, case))}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      invalid_changeset ->
        {:noreply, assign(socket, :changeset, invalid_changeset)}
    end
  end

  # defp load_people_by_id(ids) do
  #   CaseContext.list_people_by_ids(ids)
  # end
end
