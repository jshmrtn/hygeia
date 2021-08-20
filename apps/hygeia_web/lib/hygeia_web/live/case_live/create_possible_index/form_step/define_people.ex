defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.CaseSnippet
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople.Search

  alias Surface.Components.Form
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.HiddenInput
  alias Surface.Components.Link
  alias Surface.Components.LivePatch
  alias Surface.Components.Form.Input.InputContext

  @search_debounce 400

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop params, :map, default: %{}
  prop current_form_data, :map, required: true
  prop tenants, :list, required: true

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

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: CaseContext.change_person(%Person{}),
       search_params: Search.changeset(%Search{}),
       bindings: [],
       bulk_action_elements: %{},
       propagator: nil,
       suggestions: [],
       loading: false,
       live_action: :index
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(propagator: assigns.current_form_data |> Map.get(:propagator))
     |> assign(:bindings, assigns.current_form_data |> Map.get(:bindings, []))
     |> handle_action(assigns.live_action, assigns.params)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_person", %{"person" => params}, socket) do
    {
      :noreply,
      socket
      |> assign(:changeset, validation_changeset(Person, params))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save_person", %{"person" => person_params}, socket) do
    %{
      assigns: %{
        bindings: bindings,
        tenants: tenants,
        current_form_data: current_form_data,
        form_step: form_step,
        live_action: live_action,
        params: params
      }
    } = socket

    %Person{}
    |> CaseContext.change_person(person_params)
    |> case do
      %Ecto.Changeset{valid?: true} = person_changeset ->
        type = current_form_data[:type]
        person_uuid = get_field(person_changeset, :uuid)
        tenant_uuid = get_field(person_changeset, :tenant_uuid)

        %{
          person_changeset: merge_tenant(person_changeset, tenants),
          case_changeset:
            change(%Case{}, %{
              person_uuid: person_uuid,
              tenant_uuid: tenant_uuid,
              status: decide_case_status(type)
            })
        }
        |> include_binding(bindings, live_action, params)
        |> then(&send(self(), {:feed, %{bindings: &1}}))

        send(
          self(),
          {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
        )

        {:noreply,
         socket
         |> assign(:suggestions, [])
         |> assign(:search_params, Search.changeset(%Search{}))}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply,
         socket
         |> assign(:changeset, changeset |> Map.put(:action, :validate))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest_people", %{"search" => search_params}, socket) do
    %{assigns: %{suggestions: prev_suggestions, bindings: bindings}} = socket

    changeset = validation_changeset(Search, search_params)

    suggestions =
      changeset
      |> case do
        %Ecto.Changeset{valid?: true, changes: changes} ->
          changes
          |> CaseContext.suggest_people_by_params([:tenant, :cases])
          |> discard_used_suggestions(bindings)

        _ ->
          prev_suggestions
      end

    {:noreply,
     socket
     |> assign(:search_params, changeset)
     |> assign(:suggestions, suggestions)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear_search", _, socket) do
    {:noreply,
     socket
     |> assign(:search_params, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("copy_address_from_propagator", _, socket) do
    %{assigns: %{changeset: changeset, propagator: {propagator, _case}}} = socket

    address = %{
      address: propagator.address |> Map.from_struct()
    }

    {:noreply,
     socket
     |> assign(:changeset, validation_changeset(changeset, Person, address))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_selected", %{"value" => person_uuid}, socket) do
    %{
      assigns: %{
        current_form_data: current_form_data,
        bindings: bindings,
        suggestions: suggestions,
        form_step: form_step
      }
    } = socket

    type = current_form_data[:type]
    person = get_suggested_person(suggestions, person_uuid)
    tenant_uuid = Map.get(person, :tenant_uuid)

    %{
      person_changeset: person |> CaseContext.change_person(),
      case_changeset:
        Ecto.build_assoc(person, :cases) |> change(%{tenant_uuid: tenant_uuid, status: decide_case_status(type)})
    }
    |> add_binding(bindings)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:search_params, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("case_selected", %{"person_uuid" => person_uuid, "value" => case_uuid}, socket) do
    %{
      assigns: %{
        bindings: bindings,
        suggestions: suggestions,
        form_step: form_step
      }
    } = socket

    person = get_suggested_person(suggestions, person_uuid)
    case = get_suggested_person_case(suggestions, case_uuid)

    %{
      person_changeset: person |> CaseContext.change_person(),
      case_changeset: case |> CaseContext.change_case()
    }
    |> add_binding(bindings)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:search_params, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("duplicate_person_selected", %{"value" => person_uuid}, socket) do
    %{
      assigns: %{
        current_form_data: current_form_data,
        bindings: bindings,
        form_step: form_step,
        live_action: live_action,
        params: params
      }
    } = socket

    type = current_form_data[:type]
    person = CaseContext.get_person!(person_uuid) |> Hygeia.Repo.preload(:tenant)
    tenant_uuid = Map.get(person, :tenant_uuid)

    %{
      person_changeset: person |> CaseContext.change_person(),
      case_changeset:
        Ecto.build_assoc(person, :cases) |> change(%{tenant_uuid: tenant_uuid, status: decide_case_status(type)})
    }
    |> include_binding(bindings, live_action, params)
    |> then(&send(self(), {:feed, %{bindings: &1}}))

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:changeset, CaseContext.change_person(%Person{}))
     |> assign(:search_params, Search.changeset(%Search{}))
     |> assign(:suggestions, [])}
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"index" => index, "value" => "true"}, socket) do
    {
      :noreply,
      socket
      |> assign(
        :bulk_action_elements,
        add_to_bulk_action(socket.assigns.bulk_action_elements, index)
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"index" => index}, socket) do
    {
      :noreply,
      socket
      |> assign(
        :bulk_action_elements,
        remove_from_bulk_action(socket.assigns.bulk_action_elements, index)
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", %{"value" => "true"}, socket) do
    %{assigns: %{bindings: bindings}} = socket

    bulk_action_elements =
      0..(length(bindings) - 1)
      |> Enum.map(&{"#{&1}", &1})
      |> Enum.into(%{})

    {
      :noreply,
      socket
      |> assign(:bulk_action_elements, bulk_action_elements)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", _, socket) do
    {
      :noreply,
      socket
      |> assign(:bulk_action_elements, empty_bulk_action())
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("apply_bulk_action", _, socket) do
    bindings =
      socket.assigns.bindings
      |> bulk_delete(socket.assigns.bulk_action_elements)

    send(self(), {:feed, %{bindings: bindings}})

    {
      :noreply,
      socket
      |> assign(bindings: bindings)
      |> assign(bulk_action_elements: empty_bulk_action())
    }
  end

  def handle_event(
        "add_contact_method",
        _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
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
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {:noreply,
     socket
     |> assign(
       :changeset,
       CaseContext.change_person(
         %Person{},
         changeset_remove_from_params_by_id(changeset, :contact_methods, %{uuid: uuid})
       )
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("discard_person", _params, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> assign(:changeset, CaseContext.change_person(%Person{}))
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :index, form_step),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :index, form_step),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("new_person_modal", %{"search" => params}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    %{
      "mobile" => mobile,
      "landline" => landline,
      "email" => email
    } = params

    send(
      self(),
      {:push_patch, Routes.case_create_possible_index_path(socket, :new, form_step), true}
    )

    {:noreply,
     socket
     |> assign(:changeset, %{
       (CaseContext.change_person(%Person{}, params)
        |> merge_contact_method(:mobile, mobile)
        |> merge_contact_method(:landline, landline)
        |> merge_contact_method(:email, email))
       | action: :validate
     })
     |> assign(:bulk_action_elements, %{})}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_person", %{"index" => index}, socket) do
    %{assigns: %{bindings: bindings, bulk_action_elements: elements}} = socket

    bindings = List.delete_at(bindings, String.to_integer(index))

    send(self(), {:feed, %{bindings: bindings}})

    {:noreply,
     socket
     |> assign(:bulk_action_elements, remove_from_bulk_action(elements, index))}
  end

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

  defp handle_action(socket, :show, %{"form_step" => form_step, "index" => index}) do
    %{assigns: %{bindings: bindings}} = socket

    bindings
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

        socket
        |> assign(changeset: validation_changeset(person_changeset, Person, %{}))
    end
  end

  defp handle_action(socket, :edit, %{"form_step" => form_step, "index" => index}) do
    %{assigns: %{bindings: bindings}} = socket

    bindings
    |> Enum.at(String.to_integer(index))
    |> case do
      nil ->
        send(
          self(),
          {:push_patch, Routes.case_create_possible_index_path(socket, :index, form_step), true}
        )

        # TODO set live_action to :index
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
          socket
          |> assign(changeset: validation_changeset(person_changeset, Person, %{}))
        end
    end
  end

  defp handle_action(socket, _, _) do
    socket
  end

  defp include_binding(binding, bindings, live_action, params)
  defp include_binding(binding, bindings, :new, _params) do
    add_binding(binding, bindings)
  end

  defp include_binding(binding, bindings, _, params) do
    case Map.get(params, "index") do
      nil -> bindings
      index -> List.replace_at(bindings, String.to_integer(index), binding)
    end
  end

  defp add_binding(binding, bindings) when is_list(bindings) do
    [binding] ++ bindings
  end

  defp remove_binding_by_person_uuid(bindings, person_uuid) do
    Enum.reject(bindings, fn %{person_changeset: person_changeset} ->
      match?(^person_uuid, fetch_field!(person_changeset, :uuid))
    end)
  end

  defp get_suggested_person(suggestions, person_uuid) do
    suggestions
    |> Enum.find_value(fn person ->
      if person.uuid == person_uuid,
        do: person
    end)
  end

  defp get_suggested_person_case(suggestions, case_uuid) do
    suggestions
    |> Enum.find_value(fn person ->
        Enum.find(person.cases, fn case -> case.uuid == case_uuid end)
    end)
  end

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

  defp empty_bulk_action() do
    %{}
  end

  defp in_bulk_action?(bulk_action_elements, index) do
    Map.has_key?(bulk_action_elements, "#{index}")
  end

  defp is_all_checked?(bindings, bulk_action_elements) do
    length(bindings) == map_size(bulk_action_elements)
  end

  defp bulk_delete([], _) do
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

  defp contains?(nil, _), do: false
  defp contains?(_, nil), do: false

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
      tenants
      |> Enum.find(fn tenant -> tenant.uuid == tenant_uuid end)
    )
  end

  defp decide_case_status(type) when type in [:contact_person, :travel], do: :done

  defp decide_case_status(_), do: :first_contact

  def valid?(nil), do: false

  def valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn %{person_changeset: person_changeset}, truth ->
      person_changeset.valid? and truth
    end)
  end

  defp debounce() do
    @search_debounce
  end
end
