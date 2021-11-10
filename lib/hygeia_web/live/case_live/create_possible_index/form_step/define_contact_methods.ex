defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineContactMethods do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import HygeiaGettext
  import Ecto.Changeset

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

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

  @spec group_contacts_by_type(Ecto.Changeset.t(%Person{})) :: list()
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

  defp prefill_reporting_data(%{type: type} = form_data) do
    Map.update(form_data, :bindings, [], fn bindings ->
      {updated_bindings, should_feed} =
        Enum.map_reduce(bindings, false, fn
          %{reporting: reporting} = binding, should_feed when is_list(reporting) ->
            {binding, should_feed or false}

          %{person_changeset: person_changeset, case_changeset: case_changeset} = binding,
          should_feed ->
            if should_contact_person(case_changeset, type) do
              {Map.put(
                 binding,
                 :reporting,
                 add_contact_uuids(
                   [],
                   person_changeset
                   |> fetch_field!(:contact_methods)
                   |> Enum.map(& &1.uuid)
                 )
               ), true}
            else
              {Map.put(binding, :reporting, []), true}
            end
        end)

      if should_feed do
        send(self(), {:feed, %{bindings: updated_bindings}})
      end

      updated_bindings
    end)
  end

  defp prefill_reporting_data(form_data), do: form_data

  defp should_contact_person(case_changeset, type),
    do: not has_index_phase?(case_changeset) and is_right_type?(type)

  defp has_index_phase?(case_changeset) do
    case_changeset
    |> fetch_field!(:phases)
    |> Enum.find(&match?(%Case.Phase{details: %Case.Phase.Index{}}, &1))
    |> case do
      nil -> false
      %Case.Phase{} -> true
    end
  end

  defp is_right_type?(transmission_type)
  defp is_right_type?(:contact_person), do: false
  defp is_right_type?(_other), do: true

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
    contacts
    |> Enum.map(& &1.uuid)
    |> Enum.join(",")
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
