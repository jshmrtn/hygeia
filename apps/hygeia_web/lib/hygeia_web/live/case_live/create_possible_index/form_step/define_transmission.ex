defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import Ecto.Changeset
  import HygeiaGettext

  alias Phoenix.LiveView.Socket

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Person
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.Case.Phase.PossibleIndex.Type
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.CaseContext.Transmission.InfectionPlace

  alias HygeiaWeb.DateInput
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

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

  data changeset, :map

  @impl Phoenix.LiveComponent
  def update(%{current_form_data: current_form_data} = assigns, socket) do
    changeset =
      %__MODULE__{}
      |> changeset(current_form_data)
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
    normalized_params = normalize_params(params)
    send(self(), {:feed, normalized_params})

    {:noreply, assign(socket, :changeset, validation_changeset(__MODULE__, params))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "next",
        _params,
        %Socket{assigns: %{current_form_data: current_form_data}} = socket
      ) do
    case valid?(current_form_data) do
      true ->
        send(self(), :proceed)
        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "change_propagator_case",
        params,
        %Socket{assigns: %{changeset: changeset}} = socket
      ) do
    updated_params =
      update_changeset_param(
        changeset,
        :propagator_case_uuid,
        fn _value_before -> params["uuid"] end
      )

    send(
      self(),
      {:feed,
       %{
         propagator_case_uuid: params["uuid"],
         propagator: get_propagator_from_case_uuid(params["uuid"])
       }}
    )

    {:noreply, assign(socket, :changeset, validation_changeset(__MODULE__, updated_params))}
  end

  @impl Phoenix.LiveComponent
  def handle_event(_other, _params, socket) do
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

  @spec update_step_data(form_data :: map(), changed_data :: map()) :: map()
  def update_step_data(form_data, changed_data)
  def update_step_data(form_data, _data), do: form_data

  @spec valid?(step_data :: map()) :: boolean()
  def valid?(step_data) do
    %__MODULE__{}
    |> changeset(step_data)
    |> then(& &1.valid?)
  end

  defp get_propagator_from_case_uuid(case_uuid)
  defp get_propagator_from_case_uuid(nil), do: nil

  defp get_propagator_from_case_uuid(case_uuid) do
    case = CaseContext.get_case_with_preload!(case_uuid, [:person])
    person = Map.get(case, :person)
    {person, case}
  end

  defp normalize_params(params) do
    Map.new(params, fn
      {"type", type} ->
        {:type, String.to_existing_atom(type)}

      {k, v} ->
        {String.to_existing_atom(k), v}
    end)
  end
end
