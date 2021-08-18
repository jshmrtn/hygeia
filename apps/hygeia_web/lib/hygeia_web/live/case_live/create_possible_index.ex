defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.{
    DefineTransmission,
    DefinePeople,
    DefineOptions,
    Reporting,
    Summary
  }

  alias Surface.Components.LivePatch
  alias Surface.Components.Form.HiddenInput
  alias HygeiaWeb.Helpers.FormStep

  @default_form_step "transmission"
  @form_steps [
    %FormStep{name: "transmission", prev: nil, next: "people"},
    %FormStep{name: "people", prev: "transmission", next: "options"},
    %FormStep{name: "options", prev: "people", next: "reporting"},
    %FormStep{name: "reporting", prev: "options", next: nil},
    %FormStep{name: "summary", prev: nil, next: nil}
  ]

  @impl Phoenix.LiveView
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def mount(params, _session, socket) do
    socket =
      if authorized?(Case, :create, get_auth(socket), tenant: :any) do
        tenants =
          Enum.filter(
            TenantContext.list_tenants(),
            &authorized?(Case, :create, get_auth(socket), tenant: &1)
          )

        supervisor_users =
          tenants
          |> Enum.reduce(%{}, fn tenant, acc ->
            Map.put(acc, tenant.uuid, UserContext.list_users_with_role(:supervisor, tenant))
          end)

        tracer_users =
          tenants
          |> Enum.reduce(%{}, fn tenant, acc ->
            Map.put(acc, tenant.uuid, UserContext.list_users_with_role(:tracer, tenant))
          end)

        normalized_params =
          params
          |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

        available_data =
          case params["possible_index_submission_uuid"] do
            nil ->
              normalized_params

              # alias Hygeia.CaseContext.Person

              # %Person{tenant_uuid: tenant_uuid} =
              #   person1 =
              #   CaseContext.get_person!("e3239c4f-a98a-46f1-8e09-0fb412599d44")
              #   |> Hygeia.Repo.preload([:tenant, :cases])

              # %{
              #   type: :travel,
              #   date: Date.add(Date.utc_today(), -5) |> Date.to_iso8601(),
              #   bindings: [
              #     %{
              #       person_changeset: person1 |> CaseContext.change_person(),
              #       case_changeset: List.first(person1.cases) |> Ecto.Changeset.change()
              #       # EMPTY CASE
              #       # Ecto.build_assoc(person1, :cases, %{tenant_uuid: tenant_uuid, status: :done})
              #       # |> Ecto.Changeset.change()
              #     }
              #   ]
              # }
              # |> Map.merge(normalized_params)

            uuid ->
              Map.merge(normalized_params, possible_index_submission_attrs(uuid))
          end

        assign(socket,
          control_step: @default_form_step,
          current_form_data: available_data,
          tenants: tenants,
          supervisor_users: supervisor_users,
          tracer_users: tracer_users,
          return_to: params["return_to"],
          page_title: "#{gettext("Create Possible Index Cases")} - #{gettext("Cases")}"
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    %{assigns: %{control_step: control_step}} = socket

    form_step =
      @form_steps
      |> FormStep.member?(params["form_step"])
      |> case do
        true -> params["form_step"]
        false -> @default_form_step
      end

    socket =
      if FormStep.reachable?(@form_steps, form_step, control_step) do
        assign(socket, :form_step, form_step)
      else
        push_patch(socket,
          to: Routes.case_create_possible_index_path(socket, :index, @default_form_step)
        )
      end

    {:noreply,
     socket
     |> assign(:params, params)}
  end

  def save(socket) do
    %{assigns: %{current_form_data: current_form_data}} = socket

    bindings = Map.fetch!(current_form_data, :bindings)

    {:ok, tuples} = Service.upsert(bindings, current_form_data)

    :ok = Service.send_confirmations(socket, tuples, current_form_data)

    socket
    |> assign(control_step: "summary")
    |> put_flash(:info, gettext("Cases inserted successfully."))
    |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, "summary"))
  end

  @impl Phoenix.LiveView
  def handle_info(:proceed, socket) do
    {:noreply,
     socket
     |> change_step(@form_steps, :next)}
  end

  @impl Phoenix.LiveView
  def handle_info(:return, socket) do
    {:noreply,
     socket
     |> change_step(@form_steps, :prev)}
  end

  @impl Phoenix.LiveView
  def handle_info({:proceed, form_data}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Map.merge(form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)
     |> change_step(@form_steps, :next)}
  end

  @impl Phoenix.LiveView
  def handle_info({:return, form_data}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Map.merge(form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)
     |> change_step(@form_steps, :prev)}
  end

  def handle_info({:feed, form_data}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Map.merge(form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)}
  end

  def handle_info({:push_patch, path, replace?}, socket) do
    {:noreply,
     socket
     |> push_patch(to: path, replace: replace?)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp possible_index_submission_attrs(uuid) do
    %PossibleIndexSubmission{
      case_uuid: case_uuid,
      comment: comment,
      transmission_date: transmission_date,
      infection_place: infection_place,
      first_name: first_name,
      last_name: last_name,
      sex: sex,
      birth_date: birth_date,
      mobile: mobile,
      landline: landline,
      email: email,
      address: address
    } = CaseContext.get_possible_index_submission!(uuid)

    %{
      :comment => comment,
      :propagator_internal => true,
      :propagator_case_uuid => case_uuid,
      :type => :contact_person,
      :date => Date.to_iso8601(transmission_date),
      :infection_place =>
        infection_place
        |> Map.from_struct()
        |> Map.put(:address, Map.from_struct(infection_place.address))
        |> Map.drop([:type]),
      :bindings => [
        %{
          person_changeset:
            CaseContext.change_person(%Person{}, %{
              first_name: first_name,
              last_name: last_name,
              sex: sex,
              birth_date: birth_date,
              mobile: mobile,
              landline: landline,
              email: email,
              address: Map.from_struct(address)
            }),
          case_changeset: CaseContext.change_case(%Case{})
        }
      ]
    }
  end

  defp change_step(socket, steps, :prev) do
    %{assigns: %{form_step: form_step}} = socket

    if new_step = FormStep.get_previous_step(steps, form_step) do
      push_patch(socket, to: Routes.case_create_possible_index_path(socket, :index, new_step))
    else
      socket
    end
  end

  defp change_step(socket, steps, :next) do
    %{assigns: %{form_step: form_step, control_step: control_step}} = socket

    if new_step = FormStep.get_next_step(steps, form_step) do
      socket
      |> assign(control_step: update_control_step(steps, control_step, new_step))
      |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, new_step))
    else
      save(socket)
    end
  end

  defp update_control_step(steps, control_step, possible_control_step) do
    if FormStep.reachable?(steps, control_step, possible_control_step) do
      possible_control_step
    else
      control_step
    end
  end

  def get_form_steps() do
    @form_steps
  end
end
