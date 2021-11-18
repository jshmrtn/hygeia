defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineContactMethods do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import HygeiaGettext
  import Ecto.Changeset

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineAdministration
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias Surface.Components.Form.Checkbox

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop form_data, :map, required: true

  #

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

  @spec update_step_data(form_data :: map()) :: map()
  def update_step_data(form_data)

  def update_step_data(form_data) do
    Map.update(
      form_data,
      :bindings,
      [],
      &clean_reporting_data(&1)
    )
  end

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
    if can_contact_person?(case_changeset, transmission_type) and
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

  defp can_contact_person?(case_changeset, type),
    do:
      not has_index_phase?(case_changeset) and is_right_type?(type) and
        is_right_tenant?(case_changeset)

  defp contact_type_eligible?(case_changeset, :email),
    do:
      TenantContext.tenant_has_outgoing_mail_configuration?(fetch_field!(case_changeset, :tenant))

  defp contact_type_eligible?(case_changeset, :mobile),
    do:
      TenantContext.tenant_has_outgoing_sms_configuration?(fetch_field!(case_changeset, :tenant))

  defp has_index_phase?(case_changeset) do
    case_changeset
    |> fetch_field!(:phases)
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

  defp disabled_contact_reason(case_changeset, type, contact_type \\ nil)

  defp disabled_contact_reason(case_changeset, type, nil) do
    gettext("This person cannot be contacted because: %{reasons}.",
      reasons:
        []
        |> index_phase_reason(case_changeset)
        |> type_reason(type)
        |> tenant_reason(case_changeset)
        |> Enum.join(", ")
    )
  end

  defp disabled_contact_reason(case_changeset, _type, :email) do
    gettext("This person cannot be contacted by email because: %{reasons}.",
      reasons: [] |> tenant_email_config_reason(case_changeset) |> List.first()
    )
  end

  defp disabled_contact_reason(case_changeset, _type, :mobile) do
    gettext("This person cannot be contacted by sms because: %{reasons}.",
      reasons: [] |> tenant_sms_config_reason(case_changeset) |> List.first()
    )
  end

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
    Enum.map_join(contacts, & &1.uuid, ",")
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

  @spec valid?(form_data :: map()) :: boolean()
  def valid?(form_data)

  def valid?(form_data) do
    DefineTransmission.valid?(form_data) and DefinePeople.valid?(form_data) and
      DefineAdministration.valid?(form_data)
  end
end
