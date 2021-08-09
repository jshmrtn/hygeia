defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.Reporting do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople

  alias Surface.Components.Form.Checkbox

  @primary_key false
  embedded_schema do
    field :contact_uuids, :map, default: %{}
  end

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :keyword, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       people: [],
       changeset: changeset(%__MODULE__{}),
       loading: false
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    people =
      assigns.current_form_data
      |> Keyword.get(DefinePeople, %DefinePeople{})
      |> Map.get(:people, [])

    case_uuids =
      people
      |> Enum.map(
        &(&1.cases
          |> List.first()
          |> Map.get(:uuid))
      )

    changeset =
      assigns.current_form_data
      |> Keyword.get(__MODULE__, %__MODULE__{})
      |> match_cases(case_uuids)
      |> changeset()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: changeset)
     |> assign(people: people)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "case-uuid" => case_uuid,
          "contact-uuid" => contact_uuid,
          "contact-type" => contact_type,
          "value" => "true"
        },
        socket
      ) do
    %{assigns: %{changeset: changeset}} = socket

    contact_groups =
      changeset
      |> get_field(:contact_uuids, %__MODULE__{})
      |> contact_groups(case_uuid)

    checked_contacts =
      contact_groups
      |> Map.put(
        contact_type,
        contact_groups
        |> Map.get(contact_type, [])
        |> Enum.concat([contact_uuid])
      )

    updated_changeset =
      %__MODULE__{}
      |> changeset(%{
        contact_uuids:
          changeset
          |> get_field(:contact_uuids, %__MODULE__{})
          |> Map.put(case_uuid, checked_contacts)
      })

    {:noreply, socket |> assign(:changeset, updated_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "contact_method_checked",
        %{
          "case-uuid" => case_uuid,
          "contact-uuid" => contact_uuid,
          "contact-type" => contact_type
        },
        socket
      ) do
    %{assigns: %{changeset: changeset}} = socket

    contact_groups =
      changeset
      |> get_field(:contact_uuids, %__MODULE__{})
      |> contact_groups(case_uuid)

    checked_contacts =
      contact_groups
      |> Map.put(
        contact_type,
        contact_groups
        |> Map.get(contact_type, [])
        |> Enum.reject(fn uuid -> uuid == contact_uuid end)
      )

    updated_changeset =
      %__MODULE__{}
      |> changeset(%{
        contact_uuids:
          changeset
          |> get_field(:contact_uuids, %__MODULE__{})
          |> Map.put(case_uuid, checked_contacts)
      })

    {:noreply, socket |> assign(:changeset, updated_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{
          "case-uuid" => case_uuid,
          "contact-type" => contact_type,
          "contacts" => contact_methods,
          "value" => "true"
        },
        socket
      ) do
    %{assigns: %{changeset: changeset}} = socket

    checked_contacts =
      changeset
      |> get_field(:contact_uuids, %__MODULE__{})
      |> contact_groups(case_uuid)
      |> Map.put(contact_type, to_deserialized_uuids(contact_methods))

    updated_changeset =
      %__MODULE__{}
      |> changeset(%{
        contact_uuids:
          changeset
          |> get_field(:contact_uuids, %__MODULE__{})
          |> Map.put(case_uuid, checked_contacts)
      })

    {:noreply, socket |> assign(:changeset, updated_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "all_checked",
        %{"case-uuid" => case_uuid, "contact-type" => contact_type},
        socket
      ) do
    %{assigns: %{changeset: changeset}} = socket

    checked_contacts =
      changeset
      |> get_field(:contact_uuids, %__MODULE__{})
      |> contact_groups(case_uuid)
      |> Map.put(contact_type, [])

    updated_changeset =
      %__MODULE__{}
      |> changeset(%{
        contact_uuids:
          changeset
          |> get_field(:contact_uuids, %__MODULE__{})
          |> Map.put(case_uuid, checked_contacts)
      })

    {:noreply, socket |> assign(:changeset, updated_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _, socket) do
    %{assigns: %{changeset: changeset}} = socket

    changeset
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:proceed, {__MODULE__, struct}})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("back", _, socket) do
    %{assigns: %{changeset: changeset}} = socket

    changeset
    |> apply_action(:validate)
    |> case do
      {:ok, struct} ->
        send(self(), {:return, {__MODULE__, struct}})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:contact_uuids])
  end

  defp match_cases(%__MODULE__{} = step_data, case_uuids) do
    case_uuids
    |> Enum.into(%{}, fn uuid ->
      {uuid, Map.get(step_data.contact_uuids, uuid, %{})}
    end)
    |> then(&Kernel.struct(__MODULE__, %{contact_uuids: &1}))
  end

  def case_uuid(person) do
    person.cases
    |> List.first()
    |> Map.get(:uuid)
  end

  def none_selected?(selected_contacts, case_uuid) do
    selected_contacts
    |> contact_groups(case_uuid)
    |> Enum.reduce(true, fn {_type, type_members}, truth ->
      Enum.empty?(type_members) and truth
    end)
  end

  defp contact_groups(contacts, case_uuid) do
    contacts
    |> Map.get(case_uuid, %{})
  end

  def selected_contacts(%Ecto.Changeset{} = changeset, case_uuid, contact_type) do
    changeset
    |> get_field(:contact_uuids, %{})
    |> selected_contacts(case_uuid, contact_type)
  end

  def selected_contacts(contacts, case_uuid, contact_type) do
    contacts
    |> contact_groups(case_uuid)
    |> Map.get(contact_type, [])
  end

  defp to_serialized_uuids(persons) when is_list(persons) do
    persons
    |> Enum.map(& &1.uuid)
    |> Enum.join(",")
  end

  defp to_deserialized_uuids(string_list) when is_binary(string_list) do
    string_list
    |> String.split(",")
  end

  defp all_checked?(type_contacts, checked_contacts) do
    length(type_contacts) == length(checked_contacts)
  end
end
