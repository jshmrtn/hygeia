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

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAdministration
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineContactMethods
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Summary
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias HygeiaWeb.Helpers.FormStep

  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.LivePatch

  @default_form_step :transmission
  @form_steps [
    %FormStep{name: :transmission, prev: nil, next: :people},
    %FormStep{name: :people, prev: :transmission, next: :administration},
    %FormStep{name: :administration, prev: :people, next: :contact_methods},
    %FormStep{name: :contact_methods, prev: :administration, next: nil},
    %FormStep{name: :summary, prev: nil, next: nil}
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

    form_step =
      validate_form_step(
        @form_steps,
        case params["form_step"] do
          nil -> nil
          step_name -> String.to_existing_atom(step_name)
        end
      )

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

  defp save(%Socket{assigns: %{form_data: form_data}} = socket) do
    case Service.upsert(form_data) do
      {:ok, tuples} ->
        :ok = Service.send_confirmations(socket, tuples, form_data.type)

        socket
        |> unblock_navigation()
        |> assign(visited_steps: visit_step([], :summary))
        |> put_flash(:info, gettext("Cases inserted successfully."))
        |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, :summary))

      _error ->
        socket
        |> put_flash(
          :error,
          pgettext(
            "errors",
            "There was an error while submitting the form. Please try resubmitting the form again and contact your administrator if the problem persists."
          )
        )
        |> push_patch(
          to: Routes.case_create_possible_index_path(socket, :index, @default_form_step)
        )
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
      uuid: possible_index_submission_uuid,
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
      address: address,
      employer: employer
    } = CaseContext.get_possible_index_submission!(uuid)

    %{
      possible_index_submission_uuid: possible_index_submission_uuid,
      comment: comment,
      propagator_internal: true,
      propagator_case_uuid: case_uuid,
      type: :contact_person,
      date: Date.to_iso8601(transmission_date),
      infection_place:
        infection_place
        |> Map.from_struct()
        |> Map.put(:address, Map.from_struct(infection_place.address)),
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
              address: Map.from_struct(address),
              affiliations:
                if(not is_nil(employer),
                  do: [%{unknown_organisation: %{name: employer}, kind: :employee}]
                )
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

  @spec visit_step(visited :: list(atom()), form_step :: atom()) :: list()
  def visit_step([], form_step), do: [form_step]
  def visit_step([form_step | _t] = visited, form_step), do: visited
  def visit_step([h | t], form_step), do: [h | visit_step(t, form_step)]

  @spec visited_step?(visited :: list(atom()), form_step :: atom()) :: boolean()
  def visited_step?([], _form_step), do: false
  def visited_step?([form_step | _t], form_step), do: true
  def visited_step?([_ | t], form_step), do: visited_step?(t, form_step)

  defp valid_step?(:transmission, form_data) do
    DefineTransmission.valid?(form_data)
  end

  defp valid_step?(:people, form_data) do
    DefinePeople.valid?(form_data)
  end

  defp valid_step?(:administration, form_data) do
    DefineAdministration.valid?(form_data)
  end

  defp valid_step?(:contact_methods, form_data) do
    DefineContactMethods.valid?(form_data)
  end

  defp update_form_data(current_data) do
    current_data
    |> DefineTransmission.update_step_data()
    |> DefinePeople.update_step_data()
    |> DefineAdministration.update_step_data()
    |> DefineContactMethods.update_step_data()
  end

  defp decide_nav_class(current_step, target_step, visited_steps, current_data) do
    cond do
      match?(^current_step, target_step) ->
        "active"

      valid_step?(target_step, current_data) and visited_step?(visited_steps, target_step) ->
        "completed"

      not visited_step?(visited_steps, target_step) ->
        "interactive"

      true ->
        "interactive"
    end
  end

  defp block_navigation(socket), do: push_event(socket, "block_navigation", %{})

  defp unblock_navigation(socket), do: push_event(socket, "unblock_navigation", %{})

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end

  defp translate_step(:transmission), do: pgettext("Create Possible Index Step", "Transmission")
  defp translate_step(:people), do: pgettext("Create Possible Index Step", "People")

  defp translate_step(:administration),
    do: pgettext("Create Possible Index Step", "Administration")

  defp translate_step(:contact_methods),
    do: pgettext("Create Possible Index Step", "Contact Methods")

  defp translate_step(:summary), do: pgettext("Create Possible Index Step", "Summary")
end
