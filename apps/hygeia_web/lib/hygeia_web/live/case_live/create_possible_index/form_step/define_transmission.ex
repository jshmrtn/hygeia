defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import Ecto.Changeset
  import HygeiaGettext

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Person
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Form.RadioButton

  @primary_key false
  embedded_schema do
    field :type, Type
    field :comment, :string
    field :type_other, :string

    field :date, :date
    field :propagator_ism_id, :string
    field :propagator_internal, :boolean

    embeds_one :propagator, Person
    embeds_one :infection_place, InfectionPlace

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid
  end

  prop form_step, :string, default: ""
  prop live_action, :atom, default: :index
  prop current_form_data, :map, required: true

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
    changeset =
      %__MODULE__{}
      |> changeset(assigns.current_form_data)
      |> case do
        %Ecto.Changeset{changes: changes} = changeset when map_size(changes) > 0 ->
          Map.put(changeset, :action, :validate)

        changeset ->
          changeset
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"define_transmission" => params}, socket) do
    {:noreply,
     socket
     |> assign(:changeset, validation_changeset(__MODULE__, params))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"define_transmission" => params}, socket) do
    propagator =
      params["propagator_case_uuid"]
      |> case do
        nil ->
          nil

        uuid ->
          case = CaseContext.get_case_with_preload!(uuid, [:person])
          person = Map.get(case, :person)
          {person, case}
      end

    actual_params =
      params
      |> Map.new(fn
        {"type", type} ->
          {:type, String.to_atom(type)}

        {k, v} ->
          {String.to_atom(k), v}
      end)
      |> Map.put(:propagator, propagator)

    __MODULE__
    |> validation_changeset(actual_params)
    |> case do
      %Ecto.Changeset{valid?: true} ->
        send(self(), {:proceed, actual_params})
        {:noreply, socket}

      %Ecto.Changeset{valid?: false} = changeset ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("change_propagator_case", params, socket) do
    updated_params =
      update_changeset_param(
        socket.assigns.changeset,
        :propagator_case_uuid,
        fn _value_before -> params["uuid"] end
      )

    {:noreply,
     socket
     |> assign(:changeset, validation_changeset(__MODULE__, updated_params))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(_, _params, socket) do
    {:noreply, socket}
  end

  @spec changeset(schema :: %__MODULE__{}, attrs :: map()) ::
          Ecto.Changeset.t()
  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [
      :type,
      :type_other,
      :propagator_internal,
      :propagator_ism_id,
      :propagator_case_uuid,
      :date,
      :comment
    ])
    |> cast_embed(:infection_place)
    |> validate_changeset()
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> validate_required([
      :type,
      :date
    ])
    |> validate_date()
    |> validate_type_other()
    |> Transmission.validate_case(
      :propagator_internal,
      :propagator_ism_id,
      :propagator_case_uuid
    )
  end

  @spec validate_type_other(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
  end

  @spec validate_date(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_date(changeset) do
    validate_change(changeset, :date, fn :date, value ->
      diff = Date.diff(Date.utc_today(), value)

      # TODO: Correct Validation Rules
      # diff > 10 ->
      #   [{:date, dgettext("errors", "date must not be older than 10 days")}]

      if diff < 0 do
        [{:date, dgettext("errors", "date must not be in the future")}]
      else
        []
      end
    end)
  end
end
