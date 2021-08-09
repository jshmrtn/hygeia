defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.{
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
    %FormStep{name: "reporting", prev: "options", next: "summary"},
    %FormStep{name: "summary", prev: "reporting", next: nil}
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

        available_data =
          case params["possible_index_submission_uuid"] do
            nil ->
              []
              # %Person{tenant_uuid: tenant_uuid} = person1 = CaseContext.get_person!("fe607c86-b590-484e-aab7-b52db47a5c73")
              # [
              #   {DefinePeople,
              #    %DefinePeople{
              #      people: [
              #         person1
              #         |> Map.put(:cases, [
              #          Ecto.build_assoc(person1, :cases, %{tenant_uuid: tenant_uuid}) |> CaseContext.change_case(%{phases: []})|> Ecto.Changeset.apply_changes()
              #        ])
              #      ]
              #    }}
              # For testing, replace person_uuid with existing one.
              # ]

            # TODO to keyword list
            uuid ->
              possible_index_submission_attrs(uuid)
          end

        assign(socket,
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
    form_step =
      @form_steps
      |> FormStep.get_step_names()
      |> Enum.member?(params["form_step"])
      |> case do
        true -> params["form_step"]
        false -> @default_form_step
      end

    {:noreply,
     socket
     |> assign(:params, params)
     # TODO put form_step
     |> assign(:form_step, form_step)}
  end

  def save(socket) do
    transmission_data =
      socket.assigns.current_form_data
      |> Keyword.get(DefineTransmission, %DefineTransmission{})

    people =
      socket.assigns.current_form_data
      |> Keyword.get(DefinePeople, %DefinePeople{})
      |> Map.get(:people, [])

    reporting_data =
      socket.assigns.current_form_data
      |> Keyword.get(Reporting, %Reporting{})

    people
    |> Service.upsert(transmission_data)
    #|> Service.send_notifications(reporting_data)

    socket

      #   %Ecto.Changeset{valid?: true} = changeset ->
      #     %CreateSchema{
      #       propagator_case_uuid: propagator_case_uuid,
      #       possible_index_submission_uuid: possible_index_submission_uuid
      #     } = global = Ecto.Changeset.apply_changes(changeset)

      #     propagator_case =
      #       case propagator_case_uuid do
      #         nil -> nil
      #         id -> id |> CaseContext.get_case!() |> Repo.preload(person: [])
      #       end

      #     {:ok, {cases, transmissions}} =
      #       Repo.transaction(fn ->
      #         cases =
      #           changeset
      #           |> CreateSchema.drop_empty_rows()
      #           |> Ecto.Changeset.fetch_field!(:people)
      #           |> Enum.map(&{&1, CreatePersonSchema.upsert(&1, socket, global, propagator_case)})
      #           |> Enum.map(&CreateSchema.upsert_case(&1, global))

      #         transmissions = Enum.map(cases, &CreateSchema.create_transmission(&1, global))

      #         :ok = close_submission(possible_index_submission_uuid)

      #         {cases, transmissions}
      #       end)

      #     :ok = send_confirmation_sms(socket, global, cases)

      #     :ok = send_confirmation_emails(socket, global, cases)

      #     socket =
      #       put_flash(
      #         socket,
      #         :info,
      #         ngettext("Created Case", "Created %{n} Cases", length(transmissions),
      #           n: length(transmissions)
      #         )
      #       )

      #     {:noreply, socket |> handle_save_success(CreateSchema) |> maybe_block_navigation()}
      # end
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
  def handle_info({:proceed, {module, form_data}}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Keyword.put(module, form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)
     |> change_step(@form_steps, :next)}
  end

  @impl Phoenix.LiveView
  def handle_info({:return, {module, form_data}}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Keyword.put(module, form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)
     |> change_step(@form_steps, :prev)}
  end

  def handle_info({:feed, {module, form_data}}, socket) do
    updated_data =
      socket.assigns.current_form_data
      |> Keyword.put(module, form_data)

    {:noreply,
     socket
     |> assign(:current_form_data, updated_data)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  def get_form_steps() do
    @form_steps
  end

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
      address: address,
      employer: employer
    } = CaseContext.get_possible_index_submission!(uuid)

    %{
      "comment" => comment,
      "propagator_internal" => true,
      "propagator_case_uuid" => case_uuid,
      "type" => :contact_person,
      "date" => Date.to_iso8601(transmission_date),
      "infection_place" =>
        infection_place
        |> Map.from_struct()
        |> Map.put(:address, Map.from_struct(infection_place.address))
        |> Map.drop([:type]),
      "people" => [
        %{
          first_name: first_name,
          last_name: last_name,
          sex: sex,
          birth_date: birth_date,
          mobile: mobile,
          landline: landline,
          email: email,
          address: Map.from_struct(address),
          employer: employer
        }
      ]
    }
  end

  defp get_step(steps, step_name) do
    steps
    |> Enum.find(&(&1.name == step_name))
  end

  defp change_step(socket, steps, direction) do
    current_step = get_step(steps, socket.assigns.form_step)

    if new_step = Enum.find(steps, &(&1.name == Map.get(current_step, direction))) do
      step_name = Map.get(new_step, :name)
      push_patch(socket, to: Routes.case_create_possible_index_path(socket, :index, step_name))
    else
      save(socket)
      |> put_flash(:success, gettext("The form has been submited."))
      |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, @default_form_step))
    end
  end

  # defp close_submission(uuid)
  # defp close_submission(nil), do: :ok

  # defp close_submission(uuid) do
  #   {:ok, _possible_index_submission} =
  #     uuid
  #     |> CaseContext.get_possible_index_submission!()
  #     |> CaseContext.delete_possible_index_submission()

  #   :ok
  # end

  # defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
  #   changeset
  #   |> Ecto.Changeset.get_field(:people, [])
  #   |> case do
  #     [] -> push_event(socket, "unblock_navigation", %{})
  #     [_] -> push_event(socket, "unblock_navigation", %{})
  #     [_ | _] -> push_event(socket, "block_navigation", %{})
  #   end
  # end


end
