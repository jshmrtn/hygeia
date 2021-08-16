defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
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
  alias Surface.Components.Form.Input.InputContext

  @search_debounce 500

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
        form_step: form_step,
        live_action: live_action,
        params: params
      }
    } = socket

    %Person{}
    |> CaseContext.change_person(person_params)
    |> case do
      %Ecto.Changeset{valid?: true} = person_changeset ->

        person_uuid = get_field(person_changeset, :uuid)
        tenant_uuid = get_field(person_changeset, :tenant_uuid)

        %{
          uuid: Ecto.UUID.generate(),
          person_changeset: person_changeset,
          case_changeset: change(%Case{}, %{person_uuid: person_uuid, tenant_uuid: tenant_uuid, status: :done})
        }
        |> include_binding(bindings, live_action, params)
        |> then(&( send(self(), {:feed, %{bindings: &1}}) ))

        {:noreply,
          socket
          # |> assign(:search_params, Search.changeset(%Search{}))
          # TODO investigate bug
          |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply,
         socket
         |> assign(:changeset, changeset |> Map.put(:action, :validate))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest_people", %{"search" => search_params}, socket) do
    %{assigns: %{suggestions: prev_suggestions}} = socket

    changeset = validation_changeset(Search, search_params)

    suggestions =
      changeset
      |> case do
        %Ecto.Changeset{valid?: true} ->
          CaseContext.suggest_people_by_params(search_params, [:tenant, :cases])
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
    %{assigns: %{changeset: changeset}} = socket

    address = %{
      address: socket.assigns.propagator.address |> Map.from_struct()
    }

    {:noreply,
     socket
     |> assign(:changeset, validation_changeset(changeset, Person, address))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_selected", %{"value" => person_uuid}, socket) do
    %{
      assigns: %{
        bindings: bindings,
        suggestions: suggestions,
        form_step: form_step
      }
    } = socket

    person = get_suggested_person(suggestions, person_uuid)
    tenant_uuid = Map.get(person, :tenant_uuid)

    %{
      uuid: Ecto.UUID.generate(),
      person_changeset: person |> CaseContext.change_person(),
      case_changeset: Ecto.build_assoc(person, :cases) |> change(%{tenant_uuid: tenant_uuid, status: :done})
    }
    |> add_binding(bindings)
    |> then(&( send(self(), {:feed, %{bindings: &1}}) ))


    {:noreply,
      socket
      # |> assign(:search_params, Search.changeset(%Search{}))
      |> assign(:suggestions, [])
      # TODO investigate bug
      |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}
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
    case = get_suggested_person_case(suggestions, person_uuid, case_uuid)

    %{
      uuid: Ecto.UUID.generate(),
      person_changeset: person |> CaseContext.change_person(),
      case_changeset: case |> CaseContext.change_case()
    }
    |> add_binding(bindings)
    |> then(&( send(self(), {:feed, %{bindings: &1}}) ))

    {:noreply,
      socket
      # |> assign(:search_params, Search.changeset(%Search{}))
      # TODO investigate bug
      |> assign(:suggestions, [])
      |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"binding-uuid" => uuid, "value" => "true"}, socket) do
    {
      :noreply,
      socket
      |> assign(
        :bulk_action_elements,
        add_to_bulk_action(socket.assigns.bulk_action_elements, uuid)
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"binding-uuid" => uuid}, socket) do
    {
      :noreply,
      socket
      |> assign(
        :bulk_action_elements,
        remove_from_bulk_action(socket.assigns.bulk_action_elements, uuid)
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", %{"value" => "true"}, socket) do
    %{assigns: %{bindings: bindings}} = socket

    bulk_action_elements =
      bindings
      |> Enum.map(fn %{uuid: binding_uuid} -> {binding_uuid, binding_uuid} end)
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
         changeset,
         changeset_add_to_params(changeset, :contact_methods, %{uuid: Ecto.UUID.generate()})
       )
     )}
  end

  def handle_event(
        "remove_contact_method",
        %{"uuid" => uuid} = _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do

    changeset =
      CaseContext.change_person(
        changeset,
        changeset_remove_from_params_by_id(changeset, :contact_methods, %{uuid: uuid})
      )

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
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

    {:noreply,
     socket
     |> assign(:changeset, %{
       (CaseContext.change_person(%Person{}, params)
        |> merge_contact_method(:mobile, mobile)
        |> merge_contact_method(:landline, landline)
        |> merge_contact_method(:email, email))
       | action: :validate
     })
     # |> assign(:bulk_action_elements, %{}) # Bug
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :new, form_step),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("show_person", %{"binding_uuid" => binding_uuid}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :show, form_step, binding_uuid),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("edit_person", %{"binding_uuid" => binding_uuid}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :edit, form_step, binding_uuid),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_person", %{"binding_uuid" => binding_uuid}, socket) do
    %{assigns: %{bindings: bindings, bulk_action_elements: elements}} = socket

    bindings =
      bindings
      |> Enum.reject(fn %{uuid: uuid} -> uuid == binding_uuid end)

    send(self(), {:feed, %{bindings: bindings}})

    {:noreply,
      socket
      |> assign(:bulk_action_elements, remove_from_bulk_action(elements, binding_uuid))
    }
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

  defp handle_action(socket, :show, %{"form_step" => _form_step, "uuid" => binding_uuid}) do
    %{assigns: %{bindings: bindings}} = socket

    bindings
    |> Enum.find(fn %{uuid: uuid} -> uuid == binding_uuid end)
    |> case do
      nil ->
        socket
        # |> push_patch(
        #   to: Routes.case_create_possible_index_path(socket, :index, form_step),
        #   replace: true
        # )

      binding ->
        %{person_changeset: person_changeset} = binding

        socket
        |> assign(changeset: CaseContext.change_person(person_changeset))
    end
  end

  defp handle_action(socket, :edit, %{"form_step" => _form_step, "uuid" => binding_uuid}) do
    %{assigns: %{bindings: bindings}} = socket

    bindings
    |> Enum.find(fn %{uuid: uuid} -> uuid == binding_uuid end)
    |> case do
      nil ->
        socket
        # |> push_patch(
        #   to: Routes.case_create_possible_index_path(socket, :index, form_step),
        #   replace: true
        # )
        # TODO investigate

      binding ->
        %{person_changeset: person_changeset} = binding

        if get_field(person_changeset, :inserted_at) do
          socket
          #   |> push_patch(
          #     to: Routes.case_create_possible_index_path(socket, :index, form_step),
          #     replace: true
          #   )
          # TODO Investigate alternative
        else
          socket
          |> assign(changeset: CaseContext.change_person(person_changeset))
        end
    end
  end

  defp handle_action(socket, _, _) do
    socket
  end

  defp include_binding(binding, bindings, live_action, params)

  defp include_binding(binding, bindings, :edit, params) do
    case Map.get(params, "uuid") do
      nil -> bindings
      binding_uuid -> Enum.map(bindings, fn
        %{uuid: uuid} when uuid == binding_uuid -> binding
        old_binding -> old_binding
      end)
    end
  end

  defp include_binding(binding, bindings, _, _params) do
    add_binding(binding, bindings)
  end

  defp add_binding(nil, bindings), do: bindings

  defp add_binding(binding, bindings) do
    [binding] ++ bindings
  end

  defp get_suggested_person(suggestions, person_uuid) do
    suggestions
    |> Enum.find_value(fn person ->
      if person.uuid == person_uuid,
        do: person
    end)
  end

  defp get_suggested_person_case(suggestions, person_uuid, case_uuid) do
    suggestions
    |> Enum.find_value(fn person ->
      if person.uuid == person_uuid,
        do:
          Enum.find(person.cases, fn p_case -> p_case.uuid == case_uuid end)
    end)
  end

  defp add_to_bulk_action(bulk_action_elements, uuid) do
    Map.put(bulk_action_elements, uuid, true)
  end

  defp remove_from_bulk_action(bulk_action_elements, uuid) do
    Map.delete(bulk_action_elements, uuid)
  end

  defp empty_bulk_action() do
    %{}
  end

  defp in_bulk_action?(bulk_action_elements, binding_uuid) do
    Map.has_key?(bulk_action_elements, binding_uuid)
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
    bindings
    |> Enum.reject(fn %{uuid: binding_uuid} ->
      Map.has_key?(bulk_action_elements, binding_uuid)
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

  defp valid?(bindings) do
    Enum.reduce(bindings, length(bindings) > 0, fn (%{person_changeset: person_changeset}, truth) ->
      person_changeset.valid? and truth
    end)
  end

  defp debounce() do
    @search_debounce
  end
end
