defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.TenantContext
  alias Hygeia.UserContext

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Reporting
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Summary
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias HygeiaWeb.Helpers.FormStep

  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.LivePatch

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
          Enum.reduce(tenants, %{}, fn tenant, acc ->
            Map.put(acc, tenant.uuid, UserContext.list_users_with_role(:supervisor, tenant))
          end)

        tracer_users =
          Enum.reduce(tenants, %{}, fn tenant, acc ->
            Map.put(acc, tenant.uuid, UserContext.list_users_with_role(:tracer, tenant))
          end)

        normalized_params = Map.new(params, fn {k, v} -> {String.to_existing_atom(k), v} end)

        available_data =
          case params["possible_index_submission_uuid"] do
            nil ->
              normalized_params

            # TODO: add more predefined cases.
            # alias Hygeia.CaseContext.Person

            # %Person{tenant_uuid: tenant_uuid} =
            #   person1 =
            #   CaseContext.get_person!("34e23d8c-777d-40e8-bd77-50838ba7404b")
            #   |> Hygeia.Repo.preload([:tenant, :cases])

            # %{
            #   type: :travel,
            #   date: Date.add(Date.utc_today(), -5) |> Date.to_iso8601(),
            #   bindings: [
            #     %{
            #       person_changeset: person1 |> CaseContext.change_person(),
            #       # case_changeset: List.first(person1.cases) |> Ecto.Changeset.change()
            #       # EMPTY CASE
            #       case_changeset:
            #         Ecto.build_assoc(person1, :cases, %{tenant_uuid: tenant_uuid, status: :done})
            #         |> CaseContext.change_case()
            #     }
            #   ]
            # }
            # |> Map.merge(normalized_params)

            uuid ->
              Map.merge(normalized_params, possible_index_submission_attrs(uuid))
          end

        assign(socket,
          visited_steps: visit_step([], @default_form_step),
          form_data: available_data,
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
    %{assigns: %{visited_steps: visited_steps}} = socket

    form_step = validate_form_step(@form_steps, params["form_step"])

    socket =
      if visited_step?(visited_steps, form_step) do
        assign(socket, :form_step, form_step)
      else
        push_patch(socket,
          to: Routes.case_create_possible_index_path(socket, :index, @default_form_step)
        )
      end

    {:noreply, assign(socket, :params, params)}
  end

  defp save(%Socket{assigns: %{form_data: %{bindings: bindings} = form_data}} = socket) do
    case Service.upsert(bindings, form_data) do
      {:error, _} ->
        put_flash(
          socket,
          :info,
          gettext(
            "There was an error while submitting the form. Please try resubmitting the form again and contact your administrator if the problem persists."
          )
        )

      {:ok, tuples} ->
        :ok = Service.send_confirmations(socket, tuples, form_data[:type])

        new_bindings =
          Enum.map(tuples, fn {person, case, reporting_data} ->
            %{
              person_changeset: CaseContext.change_person(person),
              case_changeset: Ecto.Changeset.change(case),
              reporting: reporting_data
            }
          end)

        socket
        |> unblock_navigation()
        |> assign(form_data: Map.put(form_data, :bindings, new_bindings))
        |> assign(visited_steps: visit_step([], "summary"))
        |> put_flash(:info, gettext("Cases inserted successfully."))
        |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, "summary"))
    end
  end

  @impl Phoenix.LiveView
  def handle_info(:proceed, socket) do
    {:noreply, change_step(socket, @form_steps, :next)}
  end

  @impl Phoenix.LiveView
  def handle_info(:return, socket) do
    {:noreply, change_step(socket, @form_steps, :prev)}
  end

  def handle_info(
        {:feed, changed_data},
        %{assigns: %{form_data: form_data}} = socket
      ) do
    updated_data =
      form_data
      |> Map.merge(changed_data)
      |> update_form_data()

    {:noreply, socket |> block_navigation() |> assign(:form_data, updated_data)}
  end

  def handle_info({:push_patch, path, replace?}, socket) do
    {:noreply, push_patch(socket, to: path, replace: replace?)}
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
      comment: comment,
      propagator_internal: true,
      propagator_case_uuid: case_uuid,
      type: :contact_person,
      date: Date.to_iso8601(transmission_date),
      infection_place:
        infection_place
        |> Map.from_struct()
        |> Map.put(:address, Map.from_struct(infection_place.address))
        |> Map.drop([:type]),
      bindings: [
        %{
          person_changeset:
            CaseContext.change_person(%Person{}, %{
              first_name: first_name,
              last_name: last_name,
              sex: sex,
              birth_date: birth_date,
              contact_methods:
                []
                |> append_if(mobile != nil and String.length(mobile) > 0, %{
                  type: :mobile,
                  value: mobile
                })
                |> append_if(landline != nil and String.length(landline) > 0, %{
                  type: :landline,
                  value: landline
                })
                |> append_if(email != nil and String.length(email) > 0, %{
                  type: :email,
                  value: email
                }),
              address: Map.from_struct(address)
            }),
          case_changeset: CaseContext.change_case(%Case{})
        }
      ]
    }
  end

  defp validate_form_step(form_steps, form_step, default_form_step \\ @default_form_step) do
    form_steps
    |> FormStep.member?(form_step)
    |> case do
      true -> form_step
      false -> default_form_step
    end
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
    %{assigns: %{form_step: form_step, visited_steps: visited_steps}} = socket

    if new_step = FormStep.get_next_step(steps, form_step) do
      socket
      |> assign(visited_steps: visit_step(visited_steps, new_step))
      |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, new_step))
    else
      save(socket)
    end
  end

  @spec get_form_steps() :: [FormStep.t()]
  def get_form_steps do
    @form_steps
  end

  @spec visit_step(visited :: list(String.t()), form_step :: String.t()) :: list()
  def visit_step([], form_step), do: [form_step]
  def visit_step([form_step | _t] = visited, form_step), do: visited
  def visit_step([h | t], form_step), do: [h | visit_step(t, form_step)]

  @spec visited_step?(visited :: list(String.t()), form_step :: String.t()) :: boolean()
  def visited_step?([], _form_step), do: false
  def visited_step?([form_step | _t], form_step), do: true
  def visited_step?([_ | t], form_step), do: visited_step?(t, form_step)

  defp valid_step?("transmission", form_data) do
    DefineTransmission.valid?(form_data)
  end

  defp valid_step?("people", form_data) do
    DefinePeople.valid?(form_data)
  end

  defp valid_step?("options", form_data) do
    DefineOptions.valid?(form_data)
  end

  defp valid_step?("reporting", form_data) do
    Reporting.valid?(form_data)
  end

  defp update_form_data(current_data) do
    current_data
    |> DefineTransmission.update_step_data()
    |> DefinePeople.update_step_data()
    |> DefineOptions.update_step_data()
    |> Reporting.update_step_data()
  end

  defp decide_nav_class(current_step, target_step, visited_steps, current_data) do
    cond do
      match?(^current_step, target_step) ->
        "bg-warning"

      valid_step?(target_step, current_data) and visited_step?(visited_steps, target_step) ->
        "bg-success"

      not visited_step?(visited_steps, target_step) ->
        ""

      true ->
        "bg-danger"
    end
  end

  defp block_navigation(socket), do: push_event(socket, "block_navigation", %{})

  defp unblock_navigation(socket), do: push_event(socket, "unblock_navigation", %{})

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end
