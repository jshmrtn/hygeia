defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Reporting do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import HygeiaGettext
  import Ecto.Changeset

  alias Hygeia.CaseContext.Case

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias Surface.Components.Form.Checkbox

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       bindings: [],
       loading: false
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    bindings =
      assigns.current_form_data
      |> Map.get(:bindings, [])
      |> clean_reporting_data()
      |> prefill_reporting_data()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:bindings, bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "index" => index,
          "contact-uuid" => contact_uuid,
          "value" => "true"
        },
        socket
      ) do
    %{assigns: %{bindings: bindings}} = socket

    updated_bindings =
      bindings
      |> List.update_at(
        String.to_integer(index),
        fn %{reporting: reporting} = binding ->
          Map.put(binding, :reporting, add_contact_uuid(reporting, contact_uuid))
        end
      )

    {:noreply, socket |> assign(:bindings, updated_bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "index" => index,
          "contact-uuid" => contact_uuid
        },
        socket
      ) do
    %{assigns: %{bindings: bindings}} = socket

    updated_bindings =
      bindings
      |> List.update_at(
        String.to_integer(index),
        fn %{reporting: reporting} = binding ->
          Map.put(binding, :reporting, remove_contact_uuid(reporting, contact_uuid))
        end
      )

    {:noreply, socket |> assign(:bindings, updated_bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{
          "index" => index,
          "contact-uuids" => contact_uuids,
          "value" => "true"
        },
        socket
      ) do
    %{assigns: %{bindings: bindings}} = socket

    updated_bindings =
      bindings
      |> List.update_at(
        String.to_integer(index),
        fn %{reporting: reporting} = binding ->
          Map.put(
            binding,
            :reporting,
            add_contact_uuids(reporting, to_deserialized_uuids(contact_uuids))
          )
        end
      )

    {:noreply, socket |> assign(:bindings, updated_bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{
          "index" => index,
          "contact-uuids" => contact_uuids
        },
        socket
      ) do
    %{assigns: %{bindings: bindings}} = socket

    updated_bindings =
      bindings
      |> List.update_at(
        String.to_integer(index),
        fn %{reporting: reporting} = binding ->
          Map.put(
            binding,
            :reporting,
            remove_contact_uuids(reporting, to_deserialized_uuids(contact_uuids))
          )
        end
      )

    {:noreply, socket |> assign(:bindings, updated_bindings)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _, socket) do
    %{assigns: %{bindings: bindings}} = socket

    send(self(), {:proceed, %{bindings: bindings}})
    {:noreply, socket}
  end

  def handle_event("back", _, socket) do
    %{assigns: %{bindings: bindings}} = socket

    send(self(), {:return, %{bindings: bindings}})
    {:noreply, socket}
  end

  def empty_reporting?(reporting) do
    map_size(reporting) == 0
  end

  def group_contacts_by_type(person_changeset) do
    person_changeset
    |> get_field(:contact_methods)
    |> Enum.group_by(& &1.type)
    |> Enum.filter(fn {type, _} -> type != :landline end)
  end

  defp clean_reporting_data(bindings) do
    bindings
    |> Enum.map(fn %{person_changeset: person_changeset} = binding ->
      reporting = Map.get(binding, :reporting, %{})

      updated_reporting =
        person_changeset
        |> get_field(:contact_methods, [])
        |> Enum.reduce(%{}, fn contact, acc ->
          if Map.has_key?(reporting, contact.uuid) do
            add_contact_uuid(acc, contact.uuid)
          else
            acc
          end
        end)

      Map.put(binding, :reporting, updated_reporting)
    end)
  end

  defp prefill_reporting_data(bindings) do
    bindings
    |> Enum.map(fn %{
                     person_changeset: person_changeset,
                     case_changeset: case_changeset,
                     reporting: reporting
                   } = binding ->
      if should_contact_person(case_changeset) do
        contact_uuids =
          person_changeset
          |> fetch_field!(:contact_methods)
          |> Enum.map(& &1.uuid)

        Map.put(binding, :reporting, add_contact_uuids(reporting, contact_uuids))
      else
        binding
      end
    end)
  end

  defp should_contact_person(case_changeset) do
    case_changeset
    |> fetch_field!(:phases)
    |> Enum.find(
      &(match?(%Case.Phase{details: %Case.Phase.Index{}}, &1) or
          match?(%Case.Phase{details: %Case.Phase.PossibleIndex{type: :contact_person}}, &1))
    )
    |> case do
      nil -> true
      %Case.Phase{} -> false
    end
  end

  defp add_contact_uuid(reporting, contact_uuid) do
    Map.put(reporting, contact_uuid, true)
  end

  defp remove_contact_uuid(reporting, contact_uuid) do
    Map.delete(reporting, contact_uuid)
  end

  defp add_contact_uuids(reporting, contact_uuids) do
    Enum.reduce(contact_uuids, reporting, fn contact_uuid, acc ->
      add_contact_uuid(acc, contact_uuid)
    end)
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
    string_list
    |> String.split(",")
  end

  def has_contact_uuid?(reporting, contact_uuid) do
    Map.has_key?(reporting, contact_uuid)
  end

  defp all_checked?(reporting, contact_type_members) do
    Enum.reduce(contact_type_members, true, fn contact, truth ->
      has_contact_uuid?(reporting, contact.uuid) and truth
    end)
  end
end
