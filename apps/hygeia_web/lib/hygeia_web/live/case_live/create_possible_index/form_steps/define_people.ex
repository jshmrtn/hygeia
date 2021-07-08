defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  alias Surface.Components.Form
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.TextInput

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :mobile, :string
    field :landline, :string

    embeds_many :people, Person, on_replace: :delete
  end

  prop current_form_data, :map, required: true
  prop tenants, :list, required: true
  prop supervisor_users, :list, required: true
  prop tracer_users, :list, required: true
  prop show_address, :boolean, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       changeset: changeset(%__MODULE__{people: [] }),
       loading: false,
       suggestions: [],
       action: :index
     )}
  end


  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset = changeset(%__MODULE__{people: []}, assigns.current_form_data)

    {:ok,
      socket
      |> assign(assigns)
      |> assign(changeset: changeset)
      |> assign(:suggestions, get_suggestions(changeset))
    }
  end


  @impl Phoenix.LiveComponent
  def handle_event("suggest", %{"person" => params}, socket) do
    changeset = changeset(%__MODULE__{}, params)

    {:noreply,
     socket
     |> assign(:changeset, %{
       changeset(%__MODULE__{}, params)
       | action: :validate
     })
     |> assign(:suggestions, get_suggestions(changeset))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("create_person", %{"person" => params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       changeset(%__MODULE__{}, params)
       | action: :validate
     })
     |> assign(:action, :new)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:action, :index)
    }
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) :: Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :uuid,
      :first_name,
      :last_name,
      :email,
      :mobile,
      :landline
    ])
    |> cast_embed(:people, required: true)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> put_embed(
      :people,
      changeset
      |> get_change(:people, [])
      |> case do
        [] -> [Person.changeset(%Person{}, %{})]
        [_entry | _other_entries] = other -> other
      end
    )
  end

  defp get_suggestions(changeset) do
    query =
    Person
    |> search_first_name(get_field(changeset, :first_name, ""))
    |> search_last_name(get_field(changeset, :last_name, ""))
    |> search_contact_method("email", get_field(changeset, :email, ""))
    |> search_contact_method("mobile", get_field(changeset, :mobile, ""))
    |> search_contact_method("landline", get_field(changeset, :landline, ""))

    query
    |> Hygeia.Repo.all()
  end

  defp search_first_name(query, ""), do: query
  defp search_first_name(query, nil), do: query

  defp search_first_name(query, first_name),
    do: CaseContext.first_name_person_search_query(query, first_name)

  defp search_last_name(query, ""), do: query
  defp search_last_name(query, nil), do: query

  defp search_last_name(query, last_name),
    do: CaseContext.last_name_person_search_query(query, last_name)

  defp search_contact_method(query, _, ""), do: query
  defp search_contact_method(query, _, nil), do: query

  defp search_contact_method(query, type, value),
    do: CaseContext.contact_method_person_search_query(query, type, value)
end
