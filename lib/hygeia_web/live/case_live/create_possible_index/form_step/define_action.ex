defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAction do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Status
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Select
  alias Surface.Components.Link

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def update(%{form_data: form_data} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(form_data: prefill_reporting_data(form_data))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "index" => index,
          "contact-uuid" => contact_uuid,
          "value" => "true"
        },
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    updated_bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn binding ->
          Map.update(binding, :reporting, [], &add_contact_uuid(&1, contact_uuid))
        end
      )

    send(self(), {:feed, %{bindings: updated_bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "index" => index,
          "contact-uuid" => contact_uuid
        },
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    updated_bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn binding ->
          Map.update(binding, :reporting, [], &remove_contact_uuid(&1, contact_uuid))
        end
      )

    send(self(), {:feed, %{bindings: updated_bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{
          "index" => index,
          "contact-uuids" => contact_uuids,
          "value" => "true"
        },
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    updated_bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn binding ->
          Map.update(
            binding,
            :reporting,
            [],
            &add_contact_uuids(
              &1,
              to_deserialized_uuids(contact_uuids)
            )
          )
        end
      )

    send(self(), {:feed, %{bindings: updated_bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{
          "index" => index,
          "contact-uuids" => contact_uuids
        },
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    updated_bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn binding ->
          Map.update(
            binding,
            :reporting,
            [],
            &remove_contact_uuids(&1, to_deserialized_uuids(contact_uuids))
          )
        end
      )

    send(self(), {:feed, %{bindings: updated_bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "validate",
        %{"index" => index, "case" => case_params},
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    bindings =
      List.update_at(
        form_data.bindings,
        String.to_integer(index),
        fn %{case_changeset: case_changeset} = binding ->
          Map.put(
            binding,
            :case_changeset,
            CaseContext.change_case(case_changeset, case_params)
          )
        end
      )

    send(self(), {:feed, %{bindings: bindings}})

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _params, socket) do
    send(self(), :proceed)
    {:noreply, socket}
  end

  def handle_event("back", _params, socket) do
    send(self(), :return)
    {:noreply, socket}
  end

  @spec empty_reporting?(reporting :: list()) :: boolean()
  def empty_reporting?(reporting) do
    Enum.empty?(reporting)
  end

  @spec group_contacts_by_type(Ecto.Changeset.t(Person.t())) :: list()
  def group_contacts_by_type(person_changeset) do
    person_changeset
    |> get_field(:contact_methods)
    |> Enum.group_by(& &1.type)
    |> Enum.filter(fn {type, _} -> type != :landline end)
  end

  @spec form_options_administrators(
          tenant_mapping :: %{String.t() => Person.t()},
          target_tenant_uuid :: String.t()
        ) ::
          list()
  def form_options_administrators(tenant_mapping, target_tenant_uuid) do
    tenant_mapping
    |> Enum.find_value(
      [],
      fn {tenant_uuid, assignees} ->
        if match?(^tenant_uuid, target_tenant_uuid),
          do: assignees
      end
    )
    |> Enum.map(&{&1.display_name, &1.uuid})
  end

  @spec update_step_data(form_data :: map()) :: map()
  def update_step_data(form_data)

  def update_step_data(%{bindings: bindings} = form_data) do
    Map.put(
      form_data,
      :bindings,
      bindings
      |> Enum.map(fn %{case_changeset: case_changeset} = binding ->
        case_changeset =
          case_changeset
          |> merge_phases(%{
            type: form_data[:type],
            type_other: form_data[:type_other],
            date: form_data[:date]
          })
          |> merge_propagator_administrators(form_data[:propagator_case])

        Map.put(binding, :case_changeset, case_changeset)
      end)
      |> clean_reporting_data()
    )
  end

  def update_step_data(form_data), do: form_data

  defp clean_reporting_data(bindings) do
    Enum.map(bindings, fn
      %{person_changeset: person_changeset, reporting: reporting} = binding ->
        updated_reporting =
          person_changeset
          |> fetch_field!(:contact_methods)
          |> Enum.reduce([], fn contact, acc ->
            if Enum.member?(reporting, contact.uuid) do
              add_contact_uuid(acc, contact.uuid)
            else
              acc
            end
          end)

        Map.put(binding, :reporting, updated_reporting)

      binding ->
        binding
    end)
  end

  defp prefill_reporting_data(%{type: transmission_type} = form_data) do
    Map.update(form_data, :bindings, [], fn bindings ->
      {updated_bindings, should_feed} =
        Enum.map_reduce(bindings, false, fn
          %{reporting: reporting} = binding, should_feed when is_list(reporting) ->
            {binding, should_feed or false}

          binding, _should_feed ->
            reporting =
              []
              |> prefill_contact_methods_type(binding, transmission_type, :email)
              |> prefill_contact_methods_type(binding, transmission_type, :mobile)

            {Map.put(binding, :reporting, reporting), true}
        end)

      if should_feed do
        send(self(), {:feed, %{bindings: updated_bindings}})
      end

      updated_bindings
    end)
  end

  defp prefill_reporting_data(form_data), do: form_data

  defp prefill_contact_methods_type(
         reporting,
         %{person_changeset: person_changeset, case_changeset: case_changeset},
         transmission_type,
         contact_type
       ) do
    if can_contact_person?(person_changeset, case_changeset, transmission_type) and
         contact_type_eligible?(case_changeset, contact_type) do
      add_contact_uuids(
        reporting,
        person_changeset
        |> fetch_field!(:contact_methods)
        |> Enum.filter(&match?(^contact_type, &1.type))
        |> Enum.map(& &1.uuid)
      )
    else
      reporting
    end
  end

  defp can_contact_person?(person_changeset, case_changeset, type),
    do:
      not has_index_phase?(case_changeset) and is_right_type?(type) and
        is_right_tenant?(case_changeset) and has_contact_methods?(person_changeset)

  defp contact_type_eligible?(case_changeset, :email),
    do:
      TenantContext.tenant_has_outgoing_mail_configuration?(fetch_field!(case_changeset, :tenant))

  defp contact_type_eligible?(case_changeset, :mobile),
    do:
      TenantContext.tenant_has_outgoing_sms_configuration?(fetch_field!(case_changeset, :tenant))

  defp has_contact_methods?(person_changeset) do
    person_changeset
    |> fetch_field!(:contact_methods)
    |> case do
      [_one | _more] -> true
      _else -> false
    end
  end

  defp has_index_phase?(case_changeset) do
    case_changeset
    |> fetch_field!(:phases)
    |> contains_index_phase?()
  end

  defp contains_index_phase?(phases) do
    phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))
    |> case do
      nil -> false
      %Case.Phase{details: %Case.Phase.Index{}} -> true
    end
  end

  defp is_right_type?(transmission_type)
  defp is_right_type?(:contact_person), do: true
  defp is_right_type?(_other), do: false

  defp is_right_tenant?(case_changeset) do
    case_changeset
    |> fetch_field!(:tenant)
    |> Tenant.is_internal_managed_tenant?()
  end

  defp disabled_contact_reason(person_cs, case_changeset, type, contact_type \\ nil)

  defp disabled_contact_reason(person_cs, case_changeset, type, nil) do
    gettext("This person cannot be contacted because: %{reasons}.",
      reasons:
        []
        |> no_contact_method_reason(person_cs)
        |> index_phase_reason(case_changeset)
        |> type_reason(type)
        |> tenant_reason(case_changeset)
        |> Enum.join(", ")
    )
  end

  defp disabled_contact_reason(_person_cs, case_changeset, _type, :email) do
    gettext("This person cannot be contacted by email because: %{reasons}.",
      reasons: [] |> tenant_email_config_reason(case_changeset) |> List.first()
    )
  end

  defp disabled_contact_reason(_person_cs, case_changeset, _type, :mobile) do
    gettext("This person cannot be contacted by sms because: %{reasons}.",
      reasons: [] |> tenant_sms_config_reason(case_changeset) |> List.first()
    )
  end

  defp no_contact_method_reason(reasons, person_changeset),
    do:
      if(has_contact_methods?(person_changeset),
        do: reasons,
        else: reasons ++ [gettext("the person does not have contact methods")]
      )

  defp index_phase_reason(reasons, case_changeset),
    do:
      if(has_index_phase?(case_changeset),
        do: reasons ++ [gettext("the case contains an index phase")],
        else: reasons
      )

  defp type_reason(reasons, type),
    do:
      if(is_right_type?(type),
        do: reasons,
        else: reasons ++ [gettext("the transmission type is not \"contact person\"")]
      )

  defp tenant_reason(reasons, case_changeset),
    do:
      if(is_right_tenant?(case_changeset),
        do: reasons,
        else: reasons ++ [gettext("the case is managed by an unmanaged tenant")]
      )

  defp tenant_email_config_reason(reasons, case_changeset),
    do:
      if(contact_type_eligible?(case_changeset, :email),
        do: reasons,
        else: reasons ++ [gettext("the assigned tenant has not configured email notifications")]
      )

  defp tenant_sms_config_reason(reasons, case_changeset),
    do:
      if(contact_type_eligible?(case_changeset, :mobile),
        do: reasons,
        else: reasons ++ [gettext("the assigned tenant has not configured sms notifications")]
      )

  defp add_contact_uuid(reporting, contact_uuid) do
    [contact_uuid] ++ reporting
  end

  defp remove_contact_uuid(reporting, contact_uuid) do
    List.delete(reporting, contact_uuid)
  end

  defp add_contact_uuids(reporting, contact_uuids) do
    contact_uuids ++ reporting
  end

  defp remove_contact_uuids(reporting, contact_uuids) do
    Enum.reduce(contact_uuids, reporting, fn contact_uuid, acc ->
      remove_contact_uuid(acc, contact_uuid)
    end)
  end

  defp to_serialized_uuids(contacts) when is_list(contacts) do
    Enum.map_join(contacts, ",", & &1.uuid)
  end

  defp to_deserialized_uuids(string_list) when is_binary(string_list) do
    String.split(string_list, ",")
  end

  @spec has_contact_uuid?(reporting :: list(), contact_uuid :: String.t()) :: boolean()
  def has_contact_uuid?(reporting, contact_uuid) do
    Enum.member?(reporting, contact_uuid)
  end

  defp all_checked?(reporting, contact_type_members) do
    Enum.reduce(contact_type_members, true, fn contact, truth ->
      has_contact_uuid?(reporting, contact.uuid) and truth
    end)
  end

  defp manage_statuses(transmission_type, statuses)
  defp manage_statuses(:travel, statuses), do: statuses
  defp manage_statuses(:contact_person, statuses), do: statuses

  defp manage_statuses(_transmission_type, statuses) do
    Enum.map(statuses, fn
      {name, :done} -> [key: name, value: :done, disabled: true]
      {name, :canceled} -> [key: name, value: :canceled, disabled: true]
      {name, code} -> [key: name, value: code]
    end)
  end

  defp merge_propagator_administrators(case_changeset, nil), do: case_changeset

  defp merge_propagator_administrators(case_changeset, propagator_case) do
    CaseContext.change_case(case_changeset, %{
      supervisor_uuid:
        get_change(case_changeset, :supervisor_uuid) || propagator_case.supervisor_uuid,
      tracer_uuid: get_change(case_changeset, :tracer_uuid) || propagator_case.tracer_uuid
    })
  end

  defp merge_phases(case_changeset, data) do
    original_phases = case_changeset.data.phases

    if contains_index_phase?(original_phases) do
      case_changeset
    else
      manage_existing_phases(case_changeset, original_phases, data)
    end
  end

  defp manage_existing_phases(
         case_changeset,
         original_phases,
         %{type: global_type, type_other: global_type_other, date: date}
       ) do
    original_phases
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: ^global_type}}, &1))
    |> case do
      nil ->
        changeset = case_changeset |> Map.put(:errors, []) |> Map.put(:valid?, true)

        case_changeset =
          if global_type in [:contact_person, :travel] do
            {start_date, end_date} = Service.phase_dates(Date.from_iso8601!(date))

            status_changed_phases =
              Enum.map(original_phases, fn
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

            put_embed(
              changeset,
              :phases,
              status_changed_phases ++
                [
                  %Case.Phase{
                    details: %Case.Phase.PossibleIndex{
                      type: global_type,
                      type_other: nil
                    },
                    quarantine_order: true,
                    order_date: DateTime.utc_now(),
                    start: start_date,
                    end: end_date
                  }
                ]
            )
          else
            put_embed(
              changeset,
              :phases,
              original_phases ++
                [
                  %Case.Phase{
                    details: %Case.Phase.PossibleIndex{
                      type: global_type,
                      type_other: global_type_other
                    }
                  }
                ]
            )
          end

        CaseContext.change_case(case_changeset)

      %Case.Phase{} ->
        put_embed(case_changeset, :phases, original_phases)
    end
  end

  @spec valid?(form_data :: map()) :: boolean()
  def valid?(form_data)

  def valid?(%{bindings: bindings}) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{case_changeset: case_changeset}, truth ->
      case_changeset.valid? and truth
    end)
  end

  def valid?(_form_data), do: false
end
