defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias Surface.Components.Form.Checkbox

  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop params, :map, default: %{}
  prop form_data, :map, required: true
  prop tenants, :list, required: true

  data changeset, :map
  data bulk_action_elements, :map, default: %{}

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(changeset: CaseContext.change_person(%Person{}))
     |> assign(modal_changeset: CaseContext.change_person(%Person{}))}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> preset_person()
     |> handle_action(assigns.live_action, assigns.params)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "update_person",
        %{"person" => params},
        %Socket{assigns: %{form_data: form_data, tenants: tenants}} = socket
      ) do
    binding =
      form_data.bindings
      |> Enum.at(String.to_integer(params["subject"]))
      |> Map.put(
        :person_changeset,
        %Person{}
        |> CaseContext.change_person(params)
        |> merge_tenant(tenants)
      )

    form_data
    |> Map.get(:bindings, [])
    |> add_binding(binding, params["subject"])
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"person" => params}, socket) do
    {:noreply,
     assign(socket, :changeset, %Ecto.Changeset{
       CaseContext.change_person(%Person{}, params)
       | action: :validate
     })}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "add_new_person",
        _params,
        %Socket{
          assigns: %{
            changeset: changeset,
            tenants: tenants,
            form_data: form_data
          }
        } = socket
      ) do
    case changeset do
      %Ecto.Changeset{valid?: true} = changeset ->
        add_new_person(changeset, form_data, tenants)

        {:noreply, clear_person(socket)}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply, assign(socket, :changeset, %Ecto.Changeset{changeset | action: :validate})}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear_person", _params, socket) do
    {:noreply, clear_person(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "copy_address_from_propagator",
        %{"index" => index},
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    binding =
      form_data.bindings
      |> Enum.at(String.to_integer(index))
      |> Map.update(:person_changeset, CaseContext.change_person(%Person{}), fn changeset ->
        CaseContext.change_person(changeset, %{
          address: Map.from_struct(form_data.propagator_case.person.address)
        })
      end)

    form_data
    |> Map.get(:bindings, [])
    |> add_binding(binding, index)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "duplicate_person_selected",
        %{"value" => person_uuid} = params,
        %Socket{
          assigns: %{
            form_data: form_data
          }
        } = socket
      ) do
    person =
      person_uuid
      |> CaseContext.get_person!()
      |> Hygeia.Repo.preload(tenant: [], affiliations: [])

    form_data
    |> Map.get(:bindings, [])
    |> Enum.reject(&match?(^person_uuid, fetch_field!(&1.person_changeset, :uuid)))
    |> add_binding(
      %{
        person_changeset: CaseContext.change_person(person),
        case_changeset:
          person
          |> Ecto.build_assoc(:cases, %{tenant_uuid: person.tenant_uuid, tenant: person.tenant})
          |> CaseContext.change_case(%{
            status: decide_case_status(form_data[:type])
          })
      },
      params["index"]
    )
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    if has_possible_index_submission?(form_data) do
      send(self(), :proceed)
    end

    {:noreply, clear_person(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "duplicate_person_case_selected",
        %{"value" => case_uuid} = params,
        %Socket{
          assigns: %{
            form_data: form_data
          }
        } = socket
      ) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Hygeia.Repo.preload(person: [:tenant, :affiliations], tenant: [])

    person_uuid = case.person.uuid

    form_data
    |> Map.get(:bindings, [])
    |> Enum.reject(&match?(^person_uuid, fetch_field!(&1.person_changeset, :uuid)))
    |> add_binding(
      %{
        person_changeset: CaseContext.change_person(case.person),
        case_changeset: CaseContext.change_case(case)
      },
      params["index"]
    )
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    if has_possible_index_submission?(form_data) do
      send(self(), :proceed)
    end

    {:noreply, clear_person(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "person_checked",
        %{"index" => index, "value" => "true"},
        %Socket{assigns: %{bulk_action_elements: bulk_action_elements}} = socket
      ) do
    {:noreply,
     assign(socket, bulk_action_elements: add_to_bulk_action(bulk_action_elements, index))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "person_checked",
        %{"index" => index},
        %Socket{assigns: %{bulk_action_elements: bulk_action_elements}} = socket
      ) do
    {
      :noreply,
      assign(socket, :bulk_action_elements, remove_from_bulk_action(bulk_action_elements, index))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{"value" => "true"},
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    {
      :noreply,
      assign(socket, :bulk_action_elements, fill_bulk_action(form_data.bindings))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", _params, socket) do
    {:noreply, clear_bulk_action(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "apply_bulk_action",
        _params,
        %Socket{assigns: %{form_data: form_data, bulk_action_elements: bulk_action_elements}} =
          socket
      ) do
    send(self(), {:feed, %{bindings: bulk_delete(form_data.bindings, bulk_action_elements)}})

    {:noreply, clear_bulk_action(socket)}
  end

  def handle_event(
        "add_contact_method",
        _params,
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       CaseContext.change_person(
         %Person{},
         changeset_add_to_params(changeset, :contact_methods, %{uuid: Ecto.UUID.generate()})
       )
     )}
  end

  def handle_event(
        "remove_contact_method",
        %{"uuid" => uuid} = _params,
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     assign(
       socket,
       :changeset,
       CaseContext.change_person(
         %Person{},
         changeset_remove_from_params_by_id(changeset, :contact_methods, %{uuid: uuid})
       )
     )}
  end

  def handle_event(
        "add_contact_method_to_card",
        %{"subject" => index},
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    binding =
      form_data.bindings
      |> Enum.at(String.to_integer(index))
      |> Map.update(:person_changeset, CaseContext.change_person(%Person{}), fn changeset ->
        CaseContext.change_person(
          %Person{},
          changeset_add_to_params(changeset, :contact_methods, %{uuid: Ecto.UUID.generate()})
        )
      end)

    form_data
    |> Map.get(:bindings, [])
    |> add_binding(binding, index)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    {:noreply, socket}
  end

  def handle_event(
        "remove_contact_method_to_card",
        %{"subject" => index, "uuid" => uuid} = _params,
        %Socket{assigns: %{form_data: form_data}} = socket
      ) do
    binding =
      form_data.bindings
      |> Enum.at(String.to_integer(index))
      |> Map.update(:person_changeset, CaseContext.change_person(%Person{}), fn changeset ->
        CaseContext.change_person(
          %Person{},
          changeset_remove_from_params_by_id(changeset, :contact_methods, %{uuid: uuid})
        )
      end)

    form_data
    |> Map.get(:bindings, [])
    |> add_binding(binding, index)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("discard_person", _params, socket) do
    {:noreply, clear_person(socket)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _params, %Socket{assigns: %{form_step: form_step}} = socket) do
    {:noreply,
     push_patch(
       socket,
       to: Routes.case_create_possible_index_path(socket, :index, form_step),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "delete_person",
        %{"value" => index},
        %Socket{assigns: %{form_data: form_data, bulk_action_elements: elements}} = socket
      ) do
    send(
      self(),
      {:feed, %{bindings: List.delete_at(form_data.bindings, String.to_integer(index))}}
    )

    {:noreply, assign(socket, :bulk_action_elements, remove_from_bulk_action(elements, index))}
  end

  def handle_event("next", _params, socket) do
    send(self(), :proceed)
    {:noreply, socket}
  end

  def handle_event("back", _params, socket) do
    send(self(), :return)
    {:noreply, socket}
  end

  @spec update_step_data(form_data :: map()) :: map()
  def update_step_data(form_data)
  def update_step_data(form_data), do: form_data

  @spec valid?(form_data :: map()) :: boolean()
  def valid?(form_data)

  def valid?(%{bindings: bindings}) do
    length(bindings) > 0 and
      Enum.all?(bindings, fn %{person_changeset: person_changeset} ->
        person_changeset.valid?
      end)
  end

  def valid?(_form_data), do: false

  defp handle_action(%Socket{assigns: %{form_data: form_data}} = socket, :show, %{
         "form_step" => form_step,
         "index" => index
       }) do
    form_data.bindings
    |> Enum.at(String.to_integer(index))
    |> case do
      nil ->
        send(
          self(),
          {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
        )

        socket

      binding ->
        %{person_changeset: person_changeset} = binding

        assign(socket, modal_changeset: %Ecto.Changeset{person_changeset | action: :validate})
    end
  end

  defp handle_action(socket, _action, _params) do
    socket
  end

  defp add_binding(bindings, binding, at_index \\ nil)

  defp add_binding(nil, binding, _any), do: [binding]

  defp add_binding(bindings, binding, nil) when is_list(bindings) do
    [binding] ++ bindings
  end

  defp add_binding(bindings, binding, index) when is_list(bindings) and is_binary(index) do
    add_binding(bindings, binding, String.to_integer(index))
  end

  defp add_binding(bindings, binding, index) when is_list(bindings) and is_integer(index) do
    List.replace_at(bindings, index, binding)
  end

  defp add_to_bulk_action(bulk_action_elements, index) do
    Map.put(bulk_action_elements, index, String.to_integer(index))
  end

  defp remove_from_bulk_action(bulk_action_elements, index) do
    Map.delete(bulk_action_elements, index)
  end

  defp fill_bulk_action(bindings) do
    0..(length(bindings) - 1)
    |> Enum.map(&{"#{&1}", &1})
    |> Enum.into(%{})
  end

  defp in_bulk_action?(bulk_action_elements, index) do
    Map.has_key?(bulk_action_elements, "#{index}")
  end

  defp is_all_checked?(bindings, bulk_action_elements) do
    length(bindings) == map_size(bulk_action_elements)
  end

  defp bulk_delete([], _bulk_action_elements) do
    []
  end

  defp bulk_delete(bindings, bulk_action_elements)
       when length(bindings) == map_size(bulk_action_elements),
       do: []

  defp bulk_delete(bindings, bulk_action_elements) do
    Enum.reduce(bulk_action_elements, bindings, fn {_, index}, acc ->
      List.delete_at(acc, index)
    end)
  end

  defp clear_person(socket, params \\ %{}) do
    assign(socket, :changeset, CaseContext.change_person(%Person{}, params))
  end

  defp clear_bulk_action(socket) do
    assign(socket, :bulk_action_elements, %{})
  end

  defp merge_tenant(changeset, tenants) do
    tenant_uuid = get_field(changeset, :tenant_uuid)

    put_assoc(
      changeset,
      :tenant,
      Enum.find(tenants, &match?(^tenant_uuid, &1.uuid))
    )
  end

  defp has_propagator_case?(form_data) do
    not is_nil(form_data[:propagator_case])
  end

  defp preset_person(%Socket{assigns: %{form_data: form_data, changeset: changeset}} = socket) do
    if fetch_field!(changeset, :tenant_uuid) do
      socket
    else
      clear_person(socket, search_data_preset(form_data))
    end
  end

  defp is_infection_place_type?(nil, _type), do: false

  defp is_infection_place_type?(infection_place, type) do
    match?(^type, infection_place[:type])
  end

  defp search_data_preset(form_data) do
    if has_propagator_case?(form_data) and
         is_infection_place_type?(form_data[:infection_place], :hh) do
      %{
        tenant_uuid: form_data.propagator_case.tenant_uuid,
        tenant: form_data.propagator_case.tenant
      }
    else
      %{}
    end
  end

  defp add_new_person(changeset, form_data, tenants) do
    person_changeset = merge_tenant(changeset, tenants)

    form_data
    |> Map.get(:bindings, [])
    |> add_binding(%{
      person_changeset: person_changeset,
      case_changeset:
        person_changeset
        |> apply_changes()
        |> Ecto.build_assoc(:cases, %{
          tenant_uuid: fetch_field!(person_changeset, :tenant_uuid),
          tenant: fetch_field!(person_changeset, :tenant)
        })
        |> CaseContext.change_case(%{
          status: decide_case_status(form_data[:type])
        })
    })
    |> then(&send(self(), {:feed, %{bindings: &1}}))
  end

  defp decide_case_status(type) when type in [:contact_person, :travel], do: :done

  defp decide_case_status(_type), do: :first_contact

  defp has_possible_index_submission?(form_data) do
    not is_nil(form_data[:possible_index_submission_uuid])
  end
end
