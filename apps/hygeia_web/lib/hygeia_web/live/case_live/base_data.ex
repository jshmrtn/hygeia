defmodule HygeiaWeb.CaseLive.BaseData do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Status
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CaseLiveHelper
  alias HygeiaWeb.DateInput
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs

  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput
  alias Surface.Components.LivePatch

  data show_complexity_help, :boolean, default: false
  data show_case_status_help, :boolean, default: false
  data show_index_phase_end_reason_help, :boolean, default: false
  data show_possible_index_phase_end_reason_help, :boolean, default: false
  data show_reasons_for_test_help, :boolean, default: false

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case = CaseContext.get_case!(id)

    auth_action =
      case socket.assigns.live_action do
        :edit -> :update
        :show -> :details
      end

    socket =
      if authorized?(case, auth_action, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")

        tenants =
          Enum.filter(
            TenantContext.list_tenants(),
            &authorized?(case, :create, get_auth(socket), tenant: &1)
          )

        supervisor_users = UserContext.list_users_with_role(:supervisor, tenants)
        tracer_users = UserContext.list_users_with_role(:tracer, tenants)

        socket
        |> load_data(case)
        |> assign(
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply, load_data(socket, case)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(
        {:hospitalisation_change_organisation, uuid, organisation_uuid},
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_update_params_by_id(
           changeset,
           :hospitalizations,
           %{uuid: uuid},
           &Map.put(&1, "organisation_uuid", organisation_uuid)
         )
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("reset", _params, socket) do
    case = CaseContext.get_case!(socket.assigns.case.uuid)

    {:noreply,
     socket
     |> load_data(socket.assigns.case)
     |> push_patch(to: Routes.case_base_data_path(socket, :show, case))
     |> maybe_block_navigation()}
  end

  def handle_event("validate", %{"case" => case_params}, socket) do
    case_params =
      case_params
      |> Map.put_new("hospitalizations", [])
      |> Map.put_new("external_references", [])

    {:noreply,
     socket
     |> assign(:changeset, %{
       CaseContext.change_case(socket.assigns.case, case_params)
       | action: :validate
     })
     |> maybe_block_navigation()}
  end

  def handle_event("save", %{"case" => case_params}, socket) do
    case_params =
      case_params
      |> Map.put_new("hospitalizations", [])
      |> Map.put_new("phases", [])
      |> Map.put_new("external_references", [])

    socket.assigns.case
    |> CaseContext.update_case(case_params)
    |> case do
      {:ok, case} ->
        {:noreply,
         socket
         |> load_data(case)
         |> put_flash(:info, gettext("Case updated successfully"))
         |> push_patch(to: Routes.case_base_data_path(socket, :show, case))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> maybe_block_navigation()}
    end
  end

  def handle_event(
        "add_external_reference",
        _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_add_to_params(changeset, :external_references, %{uuid: Ecto.UUID.generate()})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "remove_external_reference",
        %{"uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(changeset, :external_references, %{uuid: uuid})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "remove_phase",
        %{"uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(changeset, :phases, %{uuid: uuid})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "add_hospitalization",
        _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_add_to_params(changeset, :hospitalizations, %{uuid: Ecto.UUID.generate()})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "remove_hospitalization",
        %{"changeset-uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(changeset, :hospitalizations, %{uuid: uuid})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "add_test",
        _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_add_to_params(changeset, :tests, %{uuid: Ecto.UUID.generate()})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "remove_test",
        %{"changeset-uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset, case: case}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_case(
         case,
         changeset_remove_from_params_by_id(changeset, :tests, %{uuid: uuid})
       )
     )
     |> maybe_block_navigation()}
  end

  def handle_event("show_complexity_help", _params, socket) do
    {:noreply, assign(socket, show_complexity_help: true)}
  end

  def handle_event("hide_complexity_help", _params, socket) do
    {:noreply, assign(socket, show_complexity_help: false)}
  end

  def handle_event("show_index_phase_end_reason_help", _params, socket) do
    {:noreply, assign(socket, show_index_phase_end_reason_help: true)}
  end

  def handle_event("hide_index_phase_end_reason_help", _params, socket) do
    {:noreply, assign(socket, show_index_phase_end_reason_help: false)}
  end

  def handle_event("show_possible_index_phase_end_reason_help", _params, socket) do
    {:noreply, assign(socket, show_possible_index_phase_end_reason_help: true)}
  end

  def handle_event("hide_possible_index_phase_end_reason_help", _params, socket) do
    {:noreply, assign(socket, show_possible_index_phase_end_reason_help: false)}
  end

  def handle_event("show_reasons_for_test_help", _params, socket) do
    {:noreply, assign(socket, show_reasons_for_test_help: true)}
  end

  def handle_event("hide_reasons_for_test_help", _params, socket) do
    {:noreply, assign(socket, show_reasons_for_test_help: false)}
  end

  def handle_event("show_case_status_help", _params, socket) do
    {:noreply, assign(socket, show_case_status_help: true)}
  end

  def handle_event("hide_case_status_help", _params, socket) do
    {:noreply, assign(socket, show_case_status_help: false)}
  end

  defp load_data(socket, case) do
    case =
      Repo.preload(case,
        person: [tenant: []],
        tenant: [],
        hospitalizations: [organisation: []],
        tests: []
      )

    changeset = CaseContext.change_case(case)

    socket
    |> assign(case: case, changeset: changeset)
    |> assign(
      page_title: "#{case.person.first_name} #{case.person.last_name} - #{gettext("Case")}"
    )
    |> maybe_block_navigation()
  end

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
