defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.DefinePeople do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Ecto.Schema

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext.Person

  embedded_schema do
    has_many :people, Person, on_replace: :delete
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
       changeset: changeset(%__MODULE__{}),
       loading: false
     )}
  end


  @impl Phoenix.LiveComponent
  def update(assigns, socket) do


    {:ok,
      socket
      |> assign(assigns)
    }
  end


  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"define_people" => params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, %{
       changeset(%__MODULE__{}, params)
       | action: :validate
     })}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"define_people" => params}, socket) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:validate)
    |> case do
      {:ok, _struct} ->
        send(self(), {:proceed, params})
        {:noreply, socket}
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
        }
    end
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, _attrs \\ %{}) do
    schema
    |> cast_assoc(:people, required: true)
  end
end
