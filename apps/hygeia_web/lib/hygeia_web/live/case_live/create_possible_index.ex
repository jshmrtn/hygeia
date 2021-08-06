defmodule HygeiaWeb.CaseLive.CreatePossibleIndex do
  @moduledoc false

  use HygeiaWeb, :surface_view

  import HygeiaWeb.Helpers.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.ExternalReference
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CommunicationContext
  alias Hygeia.OrganisationContext.Affiliation
  alias Hygeia.OrganisationContext.Organisation
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.UserContext
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CreatePersonSchema
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.{
    DefineTransmission,
    DefinePeople,
    DefineOptions,
    Reporting,
    Summary
  }

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
              [
                {DefinePeople,
                 %DefinePeople{
                   people: [
                     CaseContext.get_person!("a01d4b12-81ee-49e6-8166-0410cb653b45")
                     |> Map.put(:cases, [
                       CaseContext.change_case(%Case{}) |> Ecto.Changeset.apply_changes()
                     ])
                   ]
                 }}
              ]

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

    upsert(transmission_data, people) |> IO.inspect()

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

  def upsert(transmission_data, people) do
    Repo.transaction(fn ->
      Enum.map(people, fn
        %Person{inserted_at: nil} = person ->
          person
          |> merge_phases(transmission_data)
          |> CaseContext.change_person()
          |> CaseContext.create_person()

        %Person{} = person ->
          person
          |> merge_phases(transmission_data)
          |> CaseContext.change_person()
          |> CaseContext.update_person()
        end
      )
    end)
  end

  defp merge_phases(person, transmission_data) do
    %{
      date: date,
      type: global_type,
      type_other: global_type_other
    } = transmission_data

    existing_phases =
      person
      |> DefineOptions.person_case()
      |> Map.get(:phases)
      # Drop Empty Phases for Create Form
      |> Enum.reject(&match?(%Case.Phase{details: nil}, &1))

    existing_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        IO.inspect("OKOK")
        if global_type in [:contact_person, :travel] do
          {start_date, end_date} = phase_dates(date)

          status_changed_phases =
            Enum.map(existing_phases, fn
              %Case.Phase{quarantine_order: true, start: old_phase_start} = phase ->
                if Date.compare(old_phase_start, start_date) == :lt do
                  %Case.Phase{
                    phase
                    | end: start_date,
                      send_automated_close_email: false
                  }
                else
                  %Case.Phase{phase | quarantine_order: false}
                end

              %Case.Phase{quarantine_order: quarantine_order} = phase
              when quarantine_order in [false, nil] ->
                phase
            end)

          person
          |> Map.put(
            :cases,
            DefineOptions.person_case(person)
            |> Map.put(
              :phases,
              status_changed_phases ++
              [
                %Case.Phase{
                  details: %Case.Phase.PossibleIndex{
                    type: global_type,
                    type_other: global_type_other
                  },
                  quarantine_order: true,
                  order_date: DateTime.utc_now(),
                  start: start_date,
                  end: end_date
                }
              ]
            ) |> then(&([&1]))
          )
        else
          person
          |> Map.put(
            :cases,
            DefineOptions.person_case(person)
            |> Map.put(
              :phases,
              existing_phases ++
                [
                  %Case.Phase{
                    details: %Case.Phase.PossibleIndex{
                      type: global_type,
                      type_other: global_type_other
                    }
                  }
                ]
            ) |> then(&([&1]))
          )
        end

      %Case.Phase{} ->
        person
    end
  end

  defp phase_dates(contact_date) do
    case contact_date do
      nil ->
        {nil, nil}

      %Date{} = contact_date ->
        start_date = contact_date
        end_date = Date.add(start_date, 9)

        start_date =
          if Date.compare(start_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            start_date
          end

        end_date =
          if Date.compare(end_date, Date.utc_today()) == :lt do
            Date.utc_today()
          else
            end_date
          end

        {start_date, end_date}
    end
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
    end
  end

  defp close_submission(uuid)
  defp close_submission(nil), do: :ok

  defp close_submission(uuid) do
    {:ok, _possible_index_submission} =
      uuid
      |> CaseContext.get_possible_index_submission!()
      |> CaseContext.delete_possible_index_submission()

    :ok
  end

  defp send_confirmation_emails(socket, global, cases)

  defp send_confirmation_emails(_socket, %CreateSchema{send_confirmation_email: false}, _cases),
    do: :ok

  defp send_confirmation_emails(
         socket,
         %CreateSchema{send_confirmation_email: true, type: type},
         cases
       ) do
    locale = Gettext.get_locale(HygeiaGettext)

    [] =
      cases
      |> Enum.map(
        &Task.async(fn ->
          case List.last(&1.phases) do
            %Phase{details: %Phase.PossibleIndex{type: ^type}} = phase ->
              Gettext.put_locale(HygeiaGettext, locale)

              CommunicationContext.create_outgoing_email(
                &1,
                quarantine_email_subject(),
                quarantine_email_body(socket, &1, phase, :email)
              )

            %Phase{} ->
              {:error, :not_latest_phase}
          end
        end)
      )
      |> Enum.map(&Task.await/1)
      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.reject(&match?({:error, :no_email}, &1))
      |> Enum.reject(&match?({:error, :no_outgoing_mail_configuration}, &1))
      |> Enum.reject(&match?({:error, :not_latest_phase}, &1))

    :ok
  end

  defp send_confirmation_sms(socket, global, cases)

  defp send_confirmation_sms(_socket, %CreateSchema{send_confirmation_sms: false}, _cases),
    do: :ok

  defp send_confirmation_sms(
         socket,
         %CreateSchema{send_confirmation_sms: true, type: type},
         cases
       ) do
    locale = Gettext.get_locale(HygeiaGettext)

    [] =
      cases
      |> Enum.map(
        &Task.async(fn ->
          case List.last(&1.phases) do
            %Phase{details: %Phase.PossibleIndex{type: ^type}, quarantine_order: false} ->
              {:error, :no_quarantine_ordered}

            %Phase{details: %Phase.PossibleIndex{type: ^type}, quarantine_order: true} = phase ->
              Gettext.put_locale(HygeiaGettext, locale)

              CommunicationContext.create_outgoing_sms(&1, quarantine_sms(socket, &1, phase))

            %Phase{} ->
              {:error, :not_latest_phase}
          end
        end)
      )
      |> Enum.map(&Task.await/1)
      |> Enum.reject(&match?({:ok, _}, &1))
      |> Enum.reject(&match?({:error, :no_mobile_number}, &1))
      |> Enum.reject(&match?({:error, :sms_config_missing}, &1))
      |> Enum.reject(&match?({:error, :not_latest_phase}, &1))
      |> Enum.reject(&match?({:error, :no_quarantine_ordered}, &1))

    :ok
  end

  defp maybe_block_navigation(%{assigns: %{changeset: changeset}} = socket) do
    changeset
    |> Ecto.Changeset.get_field(:people, [])
    |> case do
      [] -> push_event(socket, "unblock_navigation", %{})
      [_] -> push_event(socket, "unblock_navigation", %{})
      [_ | _] -> push_event(socket, "block_navigation", %{})
    end
  end

  @spec get_person_changes(person :: Person.t()) :: Ecto.Changeset.t()
  def get_person_changes(person) do
    person = Repo.preload(person, affiliations: [organisation: []])

    drop_empty_recursively_and_remove_uuid(%{
      "accepted_duplicate" => true,
      "accepted_duplicate_uuid" => person.uuid,
      "accepted_duplicate_human_readable_id" => person.human_readable_id,
      "first_name" => person.first_name,
      "last_name" => person.last_name,
      "tenant_uuid" => person.tenant_uuid,
      "mobile" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :mobile, value: value} -> value
          _other -> false
        end),
      "landline" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :landline, value: value} -> value
          _other -> false
        end),
      "email" =>
        Enum.find_value(person.contact_methods, fn
          %ContactMethod{type: :email, value: value} -> value
          _other -> false
        end),
      "sex" => person.sex,
      "birth_date" => person.birth_date,
      "employer" =>
        case person.affiliations do
          [%Affiliation{organisation: %Organisation{name: name}} | _] -> name
          [%Affiliation{comment: comment} | _] -> comment
          _other -> nil
        end,
      "address" => person.address |> Ecto.embedded_dump(:json) |> recursive_string_keys()
    })
  end

  @spec get_case_changes(person :: Case.t(), schema_module :: module()) :: Ecto.Changeset.t()
  def get_case_changes(case, schema_module) do
    phase_detail_module =
      case schema_module do
        HygeiaWeb.CaseLive.CreateIndex.CreateSchema -> Case.Phase.Index
        HygeiaWeb.CaseLive.CreatePossibleIndex.CreateSchema -> Case.Phase.PossibleIndex
      end

    keep_assignees =
      Enum.any?(case.phases, &match?(%Case.Phase{details: %^phase_detail_module{}}, &1))

    drop_empty_recursively_and_remove_uuid(%{
      "accepted_duplicate" => true,
      "accepted_duplicate_case_uuid" => case.uuid,
      "clinical" =>
        case case.clinical do
          nil -> nil
          clinical -> clinical |> Ecto.embedded_dump(:json) |> recursive_string_keys()
        end,
      "tracer_uuid" => if(keep_assignees, do: case.tracer_uuid),
      "supervisor_uuid" => if(keep_assignees, do: case.supervisor_uuid),
      "ism_case_id" =>
        Enum.find_value(case.external_references, fn
          %ExternalReference{type: :ism_case, value: value} -> value
          _other -> false
        end),
      "ism_report_id" =>
        Enum.find_value(case.external_references, fn
          %ExternalReference{type: :ism_report, value: value} -> value
          _other -> false
        end)
    })
  end

  @spec drop_empty_recursively_and_remove_uuid(input :: term) :: term
  def drop_empty_recursively_and_remove_uuid(map) when is_map(map) and not is_struct(map),
    do:
      map
      |> Enum.reject(&match?({:uuid, _value}, &1))
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Enum.map(&{elem(&1, 0), drop_empty_recursively_and_remove_uuid(elem(&1, 1))})
      |> Map.new()

  def drop_empty_recursively_and_remove_uuid(list) when is_list(list),
    do: list |> Enum.reject(&is_nil/1) |> Enum.map(&drop_empty_recursively_and_remove_uuid/1)

  def drop_empty_recursively_and_remove_uuid(other), do: other

  @spec decline_duplicate(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          schema_module :: atom
        ) ::
          Ecto.Changeset.t()
  def decline_duplicate(changeset, person_changeset_uuid, schema_module),
    do:
      schema_module.changeset(
        changeset.data,
        changeset_update_params_by_id(
          changeset,
          :people,
          %{uuid: person_changeset_uuid},
          &Map.merge(&1, %{
            "accepted_duplicate" => false,
            "accepted_duplicate_uuid" => nil
          })
        )
      )

  @spec accept_duplicate(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          person :: Person.t() | {Case.t(), Person.t()},
          schema_module :: atom
        ) :: Ecto.Changeset.t()
  def accept_duplicate(changeset, person_changeset_uuid, person_or_changeset, schema_module) do
    schema_module.changeset(
      changeset.data,
      changeset_update_params_by_id(
        changeset,
        :people,
        %{uuid: person_changeset_uuid},
        fn old_params ->
          Map.merge(
            old_params,
            case person_or_changeset do
              {case, person} ->
                Map.merge(get_person_changes(person), get_case_changes(case, schema_module))

              person ->
                get_person_changes(person)
            end,
            &recursive_map_merge/3
          )
        end
      )
    )
  end

  @spec remove_person(
          changeset :: Ecto.Changeset.t(),
          person_changeset_uuid :: Ecto.UUID.t(),
          schema_module :: atom
        ) :: Ecto.Changeset.t()
  def remove_person(changeset, person_changeset_uuid, schema_module),
    do:
      schema_module.changeset(
        changeset.data,
        changeset_remove_from_params_by_id(changeset, :people, %{uuid: person_changeset_uuid})
      )

  @spec handle_save_success(socket :: Phoenix.LiveView.Socket.t(), schema :: atom) ::
          Phoenix.LiveView.Socket.t()
  def handle_save_success(socket, schema) do
    case socket.assigns.return_to do
      nil ->
        assign(socket,
          changeset:
            schema.changeset(
              socket.assigns.changeset.data,
              update_changeset_param_relation(
                socket.assigns.changeset,
                :people,
                [:uuid],
                fn _list -> [] end
              )
            ),
          suspected_duplicate_changeset_uuid: nil,
          file: nil
        )

      uri ->
        push_redirect(socket, to: uri)
    end
  end

  defp recursive_map_merge(_key, %{} = a, %{} = b) when not is_struct(a) and not is_struct(b),
    do: Map.merge(a, b, &recursive_map_merge/3)

  defp recursive_map_merge(_key, _a, b), do: b

  defp recursive_string_keys(%{} = map) when not is_struct(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), recursive_string_keys(value)}
      {key, value} -> {key, recursive_string_keys(value)}
    end)
  end

  defp recursive_string_keys(list) when is_list(list),
    do: Enum.map(list, &recursive_string_keys/1)

  defp recursive_string_keys(other), do: other
end
