defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople.Search
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonSnippet

  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  alias Surface.Components.Link
  alias Surface.Components.LivePatch

  defmodule Search do
    @moduledoc false

    use Hygeia, :model

    @primary_key false
    embedded_schema do
      field :first_name, :string
      field :last_name, :string
      field :email, :string
      field :mobile, :string
      field :landline, :string
    end

    @spec changeset(
            person :: %__MODULE__{} | Changeset.t(),
            attrs :: Hygeia.ecto_changeset_params()
          ) ::
            Ecto.Changeset.t()
    def changeset(person \\ %__MODULE__{}, attrs \\ %{}) do
      person
      |> cast(attrs, [
        :first_name,
        :last_name,
        :email,
        :mobile,
        :landline
      ])
      |> validate_changeset()
    end

    @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
    def validate_changeset(changeset) do
      changeset
      |> validate_email(:email)
      |> validate_and_normalize_phone(:mobile, fn
        :mobile -> :ok
        :fixed_line_or_mobile -> :ok
        :personal_number -> :ok
        :unknown -> :ok
        _other -> {:error, "not a mobile number"}
      end)
      |> validate_and_normalize_phone(:landline, fn
        :fixed_line -> :ok
        :fixed_line_or_mobile -> :ok
        :voip -> :ok
        :personal_number -> :ok
        :unknown -> :ok
        _other -> {:error, "not a landline number"}
      end)
    end
  end

  @search_debounce 400

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop params, :map, default: %{}
  prop form_data, :map, required: true
  prop tenants, :list, required: true

  data changeset, :map
  data search_changeset, :map
  data bulk_action_elements, :map, default: %{}
  data propagator, :map, default: nil
  data suggestions, :list, default: []

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(changeset: CaseContext.change_person(%Person{}))
     |> assign(search_changeset: Search.changeset(%Search{}))}
  end

  @impl Phoenix.LiveComponent
  def update(%{form_data: form_data} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(propagator: form_data[:propagator])
     |> handle_action(assigns.live_action, assigns.params)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_person", %{"person" => params}, socket) do
    {:noreply, assign(socket, :changeset, validation_changeset(Person, params))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "save_person",
        %{"person" => person_params},
        %Socket{
          assigns: %{
            tenants: tenants,
            form_data: form_data,
            form_step: form_step,
            live_action: live_action,
            params: params
          }
        } = socket
      ) do
    %Person{}
    |> CaseContext.change_person(person_params)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        type = form_data[:type]
        person_changeset = merge_tenant(changeset, tenants)
        tenant_uuid = get_field(person_changeset, :tenant_uuid)

        %{
          person_changeset: person_changeset,
          case_changeset:
            person_changeset
            |> apply_changes()
            |> Ecto.build_assoc(:cases)
            |> CaseContext.change_case(%{
              tenant_uuid: tenant_uuid,
              status: decide_case_status(type)
            })
        }
        |> include_binding(form_data[:bindings], live_action, params)
        |> then(&send(self(), {:feed, %{bindings: &1}}))

        send(
          self(),
          {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
        )

        {:noreply,
         socket
         |> assign(:suggestions, [])
         |> assign(:search_changeset, Search.changeset(%Search{}))}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :validate))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "suggest_people",
        %{"search" => search_params},
        %Socket{assigns: %{suggestions: prev_suggestions, form_data: form_data}} = socket
      ) do
    changeset = validation_changeset(Search, search_params)

    suggestions =
      case changeset do
        %Ecto.Changeset{valid?: true} = changeset ->
          changeset
          |> apply_changes()
          |> CaseContext.suggest_people_by_params([:tenant, cases: [:hospitalizations]])
          |> discard_used_suggestions(form_data[:bindings])

        %Ecto.Changeset{valid?: false} ->
          prev_suggestions
      end

    {:noreply,
     socket
     |> assign(:search_changeset, changeset)
     |> assign(:suggestions, suggestions)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_changeset, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "copy_address_from_propagator",
        _params,
        %Socket{assigns: %{changeset: changeset, propagator: {propagator, _case}}} = socket
      ) do
    address = %{
      address: Map.from_struct(propagator.address)
    }

    {:noreply, assign(socket, :changeset, validation_changeset(changeset, Person, address))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "person_selected",
        %{"value" => person_uuid},
        %Socket{
          assigns: %{
            form_data: form_data,
            suggestions: suggestions,
            form_step: form_step
          }
        } = socket
      ) do
    type = form_data[:type]
    person = get_suggested_person(suggestions, person_uuid)
    tenant_uuid = Map.get(person, :tenant_uuid)

    %{
      person_changeset: CaseContext.change_person(person),
      case_changeset:
        person
        |> Ecto.build_assoc(:cases)
        |> CaseContext.change_case(%{tenant_uuid: tenant_uuid, status: decide_case_status(type)})
    }
    |> add_binding(form_data[:bindings])
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:search_changeset, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "case_selected",
        %{"person_uuid" => person_uuid, "value" => case_uuid},
        %Socket{
          assigns: %{
            form_data: form_data,
            suggestions: suggestions,
            form_step: form_step
          }
        } = socket
      ) do
    person = get_suggested_person(suggestions, person_uuid)
    case = get_suggested_case(suggestions, case_uuid)

    %{
      person_changeset: CaseContext.change_person(person),
      case_changeset: CaseContext.change_case(case)
    }
    |> add_binding(form_data.bindings)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:search_changeset, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "duplicate_person_selected",
        %{"value" => person_uuid},
        %Socket{
          assigns: %{
            form_data: form_data,
            form_step: form_step,
            live_action: live_action,
            params: params
          }
        } = socket
      ) do
    type = form_data[:type]
    person = person_uuid |> CaseContext.get_person!() |> Hygeia.Repo.preload(:tenant)
    tenant_uuid = Map.get(person, :tenant_uuid)

    %{
      person_changeset: CaseContext.change_person(person),
      case_changeset:
        person
        |> Ecto.build_assoc(:cases)
        |> CaseContext.change_case(%{tenant_uuid: tenant_uuid, status: decide_case_status(type)})
    }
    |> include_binding(form_data[:bindings], live_action, params)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:changeset, CaseContext.change_person(%Person{}))
     |> assign(:search_changeset, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
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
    {
      :noreply,
      assign(socket, :bulk_action_elements, empty_bulk_action())
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "apply_bulk_action",
        _params,
        %Socket{assigns: %{form_data: form_data, bulk_action_elements: bulk_action_elements}} =
          socket
      ) do
    send(self(), {:feed, %{bindings: bulk_delete(form_data.bindings, bulk_action_elements)}})

    {:noreply, assign(socket, bulk_action_elements: empty_bulk_action())}
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

  @impl Phoenix.LiveComponent
  def handle_event("discard_person", _params, %Socket{assigns: %{form_step: form_step}} = socket) do
    {:noreply,
     socket
     |> assign(:changeset, CaseContext.change_person(%Person{}))
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :index, form_step),
       replace: true
     )}
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
        "new_person_modal",
        %{"search" => params},
        %Socket{assigns: %{form_step: form_step}} = socket
      ) do
    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :new, form_step), true}
    )

    %{
      "mobile" => mobile,
      "landline" => landline,
      "email" => email
    } = params

    {:noreply,
     socket
     |> assign(:changeset, %{
       (%Person{}
        |> CaseContext.change_person(params)
        |> merge_contact_method(:mobile, mobile)
        |> merge_contact_method(:landline, landline)
        |> merge_contact_method(:email, email))
       | action: :validate
     })
     |> assign(:bulk_action_elements, empty_bulk_action())}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "delete_person",
        %{"index" => index},
        %Socket{assigns: %{form_data: form_data, bulk_action_elements: elements}} = socket
      ) do
    send(
      self(),
      {:feed, %{bindings: List.delete_at(form_data.bindings, String.to_integer(index))}}
    )

    {:noreply, assign(socket, :bulk_action_elements, remove_from_bulk_action(elements, index))}
  end

  def handle_event("next", _params, %Socket{assigns: %{form_data: form_data}} = socket) do
    send(self(), {:proceed, %{bindings: form_data.bindings}})
    {:noreply, socket}
  end

  def handle_event("back", _params, %Socket{assigns: %{form_data: form_data}} = socket) do
    send(self(), {:return, %{bindings: form_data.bindings}})
    {:noreply, socket}
  end

  @spec update_step_data(form_data :: map(), changed_data :: map()) :: map()
  def update_step_data(form_data, changed_data)
  def update_step_data(form_data, _data), do: form_data

  @spec valid?(form_data :: map()) :: boolean()
  def valid?(bindings)

  def valid?(%{bindings: bindings}) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{person_changeset: person_changeset}, truth ->
      person_changeset.valid? and truth
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

        assign(socket, changeset: validation_changeset(person_changeset, Person, %{}))
    end
  end

  defp handle_action(%Socket{assigns: %{form_data: form_data}} = socket, :edit, %{
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

        if existing_entity?(person_changeset) do
          send(
            self(),
            {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
          )

          socket
        else
          assign(socket, changeset: validation_changeset(person_changeset, Person, %{}))
        end
    end
  end

  defp handle_action(socket, _action, _params) do
    socket
  end

  defp include_binding(binding, bindings, live_action, params)

  defp include_binding(binding, nil, _action, _params), do: add_binding(binding, nil)

  defp include_binding(binding, bindings, :new, _params) do
    add_binding(binding, bindings)
  end

  defp include_binding(binding, bindings, _action, params) do
    case Map.get(params, "index") do
      nil -> bindings
      index -> List.replace_at(bindings, String.to_integer(index), binding)
    end
  end

  defp add_binding(binding, nil), do: [binding]

  defp add_binding(binding, bindings) when is_list(bindings) do
    [binding] ++ bindings
  end

  defp get_suggested_person(suggestions, person_uuid) do
    Enum.find_value(suggestions, fn person ->
      if person.uuid == person_uuid,
        do: person
    end)
  end

  defp get_suggested_case(suggestions, case_uuid) do
    Enum.find_value(suggestions, fn person ->
      Enum.find(person.cases, fn case -> case.uuid == case_uuid end)
    end)
  end

  defp discard_used_suggestions(suggestions, nil), do: suggestions

  defp discard_used_suggestions(suggestions, bindings) do
    Enum.reject(suggestions, fn %{uuid: uuid} ->
      Enum.any?(bindings, fn %{person_changeset: person_changeset} ->
        match?(^uuid, fetch_field!(person_changeset, :uuid))
      end)
    end)
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

  defp empty_bulk_action do
    %{}
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

  defp contains?(nil, _text2), do: false
  defp contains?(_text1, nil), do: false

  defp contains?(text1, text2) do
    String.contains?(
      String.downcase(text1),
      String.downcase(text2)
    ) or
      String.contains?(
        String.downcase(text2),
        String.downcase(text1)
      )
  end

  defp merge_contact_method(changeset, type, value)
  defp merge_contact_method(changeset, _type, nil), do: changeset
  defp merge_contact_method(changeset, _type, ""), do: changeset

  defp merge_contact_method(changeset, type, value) do
    CaseContext.change_person(
      changeset,
      changeset_add_to_params(changeset, :contact_methods, %{
        type: type,
        value: value,
        uuid: Ecto.UUID.generate()
      })
    )
  end

  defp merge_tenant(changeset, tenants) do
    tenant_uuid = get_field(changeset, :tenant_uuid)

    put_assoc(
      changeset,
      :tenant,
      Enum.find(tenants, fn tenant -> tenant.uuid == tenant_uuid end)
    )
  end

  defp decide_case_status(type) when type in [:contact_person, :travel], do: :done

  defp decide_case_status(_type), do: :first_contact

  defp debounce do
    @search_debounce
  end
end
