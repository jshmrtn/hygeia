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
  alias Hygeia.Repo

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

    field :possible_index_submission_uuid, :string

    embeds_one :propagator, Person
    embeds_one :infection_place, InfectionPlace

    belongs_to :propagator_case, Case, references: :uuid, foreign_key: :propagator_case_uuid
  end

  prop form_step, :string, default: ""
  prop live_action, :atom, default: :index
  prop form_data, :map, required: true

  data changeset, :map

  @impl Phoenix.LiveComponent
  def update(%{form_data: form_data} = assigns, socket) do
    changeset =
      %__MODULE__{}
      |> changeset(form_data)
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

    {:noreply,
     assign(socket, changeset: %Changeset{changeset(%__MODULE__{}, params) | action: :validate})}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _params, socket) do
    send(self(), :proceed)
    {:noreply, socket}
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
         propagator_case: get_propagator_case(params["uuid"])
       }}
    )

    {:noreply,
     assign(socket,
       changeset: %Changeset{changeset(%__MODULE__{}, updated_params) | action: :validate}
     )}
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
    |> validate_required([
      :type,
      :date
    ])
    |> validate_past_date(:date)
    |> validate_type_travel()
    |> validate_type_other()
    |> Transmission.validate_case(
      :propagator_internal,
      :propagator_ism_id,
      :propagator_case_uuid
    )
  end

  defp validate_type_travel(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :travel -> put_change(changeset, :propagator_internal, nil)
      _other -> changeset
    end
  end

  defp validate_type_other(changeset) do
    changeset
    |> fetch_field!(:type)
    |> case do
      :other -> validate_required(changeset, [:type_other])
      _defined -> put_change(changeset, :type_other, nil)
    end
  end

  @spec update_step_data(form_data :: map()) :: map()
  def update_step_data(form_data)
  def update_step_data(form_data), do: form_data

  @spec valid?(step_data :: map()) :: boolean()
  def valid?(step_data) do
    %__MODULE__{}
    |> changeset(step_data)
    |> then(& &1.valid?)
  end

  defp get_propagator_case(case_uuid)
  defp get_propagator_case(nil), do: nil

  defp get_propagator_case(case_uuid) do
    case_uuid
    |> CaseContext.get_case!()
    |> Repo.preload(:person)
  end

  defp normalize_params(params) when is_map(params) do
    Map.new(params, fn
      {"type", type} ->
        {:type, String.to_existing_atom(type)}

      {k, v} ->
        {String.to_existing_atom(k), normalize_params(v)}
    end)
  end

  defp normalize_params(params), do: params
end
