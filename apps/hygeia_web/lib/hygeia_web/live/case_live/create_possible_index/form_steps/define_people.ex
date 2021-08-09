defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefineTransmission
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople.Search

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

  embedded_schema do
    embeds_many :people, Person, on_replace: :delete
  end

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop params, :map, default: %{}
  prop current_form_data, :keyword, required: true
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
       people_changeset: changeset(%__MODULE__{people: []}),
       bulk_action_elements: %{},
       propagator: nil,
       search_params: Search.changeset(%Search{}),
       suggestions: [],
       loading: false,
       live_action: :index
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    people_changeset =
      assigns.current_form_data
      |> Keyword.get(__MODULE__, %__MODULE__{})
      |> changeset()

    propagator =
      assigns.current_form_data
      |> Keyword.get(DefineTransmission, %DefineTransmission{})
      |> Map.get(:propagator)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(propagator: propagator)
     |> assign(:people_changeset, people_changeset)
     |> handle_action(assigns.live_action, assigns.params)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_person", %{"person" => params}, socket) do
    changeset = %{
      CaseContext.change_person(%Person{}, params)
      | action: :validate
    }

    {
      :noreply,
      socket
      |> assign(:changeset, changeset)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_person", %{"person" => person_params}, socket) do
    %{
      assigns: %{
        people_changeset: people_changeset,
        form_step: form_step,
        tenants: tenants,
        live_action: live_action,
        params: params
      }
    } = socket

    %Person{}
    |> CaseContext.change_person(person_params)
    |> apply_action(:validate)
    |> case do
      {:ok, valid_person} ->
        valid_person
        |> set_tenant(tenants)
        |> put_empty_case()
        |> include_person(people_changeset, live_action, params)
        |> apply_action(:validate)
        |> case do
          {:ok, struct} ->
            send(self(), {:feed, {__MODULE__, struct}})

            {:noreply,
             socket
             # |> assign(:search_params, Search.changeset(%Search{}))
             # TODO investigate bug
             |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("suggest_people", %{"search" => search_params}, socket) do
    %{assigns: %{suggestions: prev_suggestions}} = socket

    changeset =
      %Search{}
      |> Search.changeset(search_params)
      |> Map.put(:action, :valiate)

    suggestions =
      changeset
      |> case do
        %{valid?: true} ->
          CaseContext.suggest_people_by_params(search_params, [
            :tenant,
            cases: :hospitalizations
          ])

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

    changeset = %{
      (changeset
       |> CaseContext.change_person(%{
         address: socket.assigns.propagator.address |> Map.from_struct()
       }))
      | action: :validate
    }

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_selected", %{"value" => person_uuid}, socket) do
    %{
      assigns: %{
        suggestions: suggestions,
        people_changeset: people_changeset,
        form_step: form_step
      }
    } = socket

    suggestions
    |> get_suggested_person(person_uuid)
    |> add_person(people_changeset)
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:feed, {__MODULE__, struct}})

        {:noreply,
         socket
         # |> assign(:search_params, Search.changeset(%Search{}))
         |> assign(:suggestions, [])
         # TODO investigate bug
         |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}

      {:error, _changeset} ->
        {
          :noreply,
          socket
          |> put_flash(:info, gettext("The selected person is already in the list."))
          |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))
        }
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("case_selected", %{"person_uuid" => person_uuid, "value" => case_uuid}, socket) do
    %{
      assigns: %{
        suggestions: suggestions,
        people_changeset: people_changeset,
        form_step: form_step
      }
    } = socket

    suggestions
    |> get_suggested_person(person_uuid, case_uuid)
    |> add_person(people_changeset)
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:feed, {__MODULE__, struct}})

        {:noreply,
         socket
         # |> assign(:search_params, Search.changeset(%Search{}))
         # TODO investigate bug
         |> assign(:suggestions, [])
         |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))}

      {:error, _changeset} ->
        {
          :noreply,
          socket
          |> put_flash(:info, gettext("The selected person is already in the list."))
          |> push_patch(to: Routes.case_create_possible_index_path(socket, :index, form_step))
        }
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"index" => index, "value" => "true"}, socket) do
    {
      :noreply,
      socket
      |> assign(
        :bulk_action_elements,
        Map.put(socket.assigns.bulk_action_elements, index, String.to_integer(index))
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("person_checked", %{"index" => index}, socket) do
    {
      :noreply,
      socket
      |> assign(:bulk_action_elements, Map.delete(socket.assigns.bulk_action_elements, index))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", %{"value" => "true"}, socket) do
    %{assigns: %{people_changeset: people_changeset}} = socket
    people_length = length(get_field(people_changeset, :people))

    bulk_action_elements =
      0..(people_length - 1)
      |> Enum.map(&{"#{&1}", &1})
      |> Enum.into(%{})

    {
      :noreply,
      socket
      |> assign(:bulk_action_elements, bulk_action_elements)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("all_checked", %{}, socket) do
    {
      :noreply,
      socket
      |> assign(:bulk_action_elements, %{})
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("apply_bulk_action", _, socket) do
    people =
      socket.assigns.people_changeset
      |> get_field(:people, [])
      |> bulk_delete(Map.values(socket.assigns.bulk_action_elements))

    {
      :noreply,
      socket
      |> assign(people_changeset: changeset(%__MODULE__{people: people}))
      |> assign(bulk_action_elements: %{})
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
    cs =
      CaseContext.change_person(
        changeset,
        changeset_remove_from_params_by_id(changeset, :contact_methods, %{uuid: uuid})
      )

    {:noreply,
     socket
     |> assign(:changeset, cs)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:changeset, CaseContext.change_person(%Person{}))}
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
        |> put_assoc(:cases, [%Case{supervisor: nil, tracer: nil}])
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
  def handle_event("show_person", %{"index" => index}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :show, form_step, index),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("edit_person", %{"index" => index}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    {:noreply,
     socket
     |> push_patch(
       to: Routes.case_create_possible_index_path(socket, :edit, form_step, index),
       replace: true
     )}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_person", %{"index" => index}, socket) do
    %{assigns: %{form_step: form_step}} = socket

    people =
      socket.assigns.people_changeset
      |> get_field(:people, [])
      |> List.delete_at(index |> String.to_integer())

    %__MODULE__{people: people}
    |> changeset()
    |> apply_changes()
    |> then(fn struct ->
      send(self(), {:feed, {__MODULE__, struct}})

      {:noreply,
       socket
       |> push_patch(
         to: Routes.case_create_possible_index_path(socket, :index, form_step),
         replace: true
       )}
    end)
  end

  def handle_event("next", _, socket) do
    %{assigns: %{people_changeset: people_changeset}} = socket

    people_changeset
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:proceed, {__MODULE__, struct}})
        {:noreply, socket}

      {:error, people_changeset} ->
        {:noreply, assign(socket, :people_changeset, people_changeset)}
    end
  end

  def handle_event("back", _, socket) do
    %{assigns: %{people_changeset: people_changeset}} = socket

    people_changeset
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:return, {__MODULE__, struct}})
        {:noreply, socket}

      {:error, _people_changeset} ->
        {:noreply, socket}
    end
  end

  defp handle_action(socket, :show, %{"form_step" => form_step, "index" => index}) do
    person_list =
      socket.assigns
      |> Map.get(:people_changeset)
      |> get_field(:people, [])

    index
    |> valid_index?(length(person_list))
    |> case do
      {:ok, index} ->
        socket
        |> assign(changeset: CaseContext.change_person(Enum.at(person_list, index)))

      {:error, _reason} ->
        socket
        |> push_patch(
          to: Routes.case_create_possible_index_path(socket, :index, form_step),
          replace: true
        )
    end
  end

  defp handle_action(socket, :edit, %{"form_step" => _form_step, "index" => index}) do
    person_list =
      socket.assigns
      |> Map.get(:people_changeset)
      |> get_field(:people, [])

    index
    |> valid_index?(length(person_list))
    |> case do
      {:ok, index} ->
        person = Enum.at(person_list, index)

        if person.inserted_at == nil do
          socket
          |> assign(changeset: CaseContext.change_person(person))
        else
          socket
          #   |> push_patch(
          #     to: Routes.case_create_possible_index_path(socket, :index, form_step),
          #     replace: true
          #   )
          # TODO Investigate alternative
        end

      {:error, _reason} ->
        socket
        # |> push_patch(
        #   to: Routes.case_create_possible_index_path(socket, :index, form_step),
        #   replace: true
        # )
        # TODO Investigate alternative
    end
  end

  defp handle_action(socket, _, _) do
    socket
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:people, required: true)
  end

  defp include_person(person, people_changeset, live_action, params)

  defp include_person(%Person{} = person, people_changeset, :edit, params) do
    index =
      params
      |> Map.get("index")

    case index do
      nil ->
        people_changeset

      index ->
        people_changeset
        |> put_embed(
          :people,
          people_changeset
          |> get_field(:people, [])
          |> List.replace_at(String.to_integer(index), person)
        )
    end
  end

  defp include_person(%Person{} = person, people_changeset, _, _params) do
    add_person(person, people_changeset)
  end

  defp add_person(nil, people_changeset) do
    people_changeset
    |> add_error(:people, "The added person is invalid or does not exist.")
  end

  defp add_person(%Person{} = person, people_changeset) do
    people_changeset
    |> put_embed(
      :people,
      people_changeset
      |> get_field(:people, [])
      |> case do
        [] ->
          [person]

        [_entry | _other_entries] = person_list ->
          [person] ++ person_list
      end
    )
    |> apply_changes()
    |> changeset()
  end

  defp get_suggested_person(suggestions, person_uuid, case_uuid \\ nil)
  defp get_suggested_person(suggestions, person_uuid, nil) do
    suggestions
    |> Enum.find_value(fn person ->
      if person.uuid == person_uuid,
        do:
          person
          |> put_empty_case()
    end)
  end

  defp get_suggested_person(suggestions, person_uuid, case_uuid) do
    suggestions
    |> Enum.find_value(fn person ->
      if person.uuid == person_uuid,
        do:
          person
          |> Map.put(:cases, [Enum.find(person.cases, fn p_case -> p_case.uuid == case_uuid end)])
    end)
  end

  defp set_tenant(%Person{tenant_uuid: tenant_uuid} = person, tenants) do
    Map.put(
      person,
      :tenant,
      tenants
      |> Enum.find(fn tenant -> tenant.uuid == tenant_uuid end)
    )
  end

  defp put_empty_case(%Person{} = person) do
    Map.put(
      person,
      :cases,
      [CaseContext.change_case(%Case{}) |> apply_changes()]
    )
  end

  defp valid_index?(nil, _length) do
    {:error, gettext("Index is nil.")}
  end

  defp valid_index?(index, length) when is_binary(index) do
    index
    |> String.to_integer()
    |> valid_index?(length)
  end

  defp valid_index?(index, length) when is_integer(index) and is_integer(length) do
    case 0 <= index && index < length do
      true -> {:ok, index}
      false -> {:error, gettext("Index is out of bounds.")}
    end
  end

  defp bulk_delete([], _) do
    []
  end

  defp bulk_delete(elements, []) do
    elements
  end

  defp bulk_delete(elements, indices) when length(elements) == length(indices), do: []

  defp bulk_delete(elements, indices) do
    elements
    |> Enum.with_index()
    |> Enum.filter(fn {_element, index} -> index not in indices end)
    |> Enum.map(&elem(&1, 0))
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

  defp debounce() do
    @search_debounce
  end
end
