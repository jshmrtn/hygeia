defmodule HygeiaWeb.CaseLive.CreatePhaseModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case.Phase
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.DateInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.RadioButton
  alias Surface.Components.Form.Select

  prop case, :map, required: true
  prop close, :event, required: true
  prop params, :map, default: %{}
  prop caller_id, :any, required: true
  prop caller_module, :atom, required: true

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    params = assigns.params || socket.assigns.params

    changeset = Phase.changeset(%Phase{}, params)

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"phase" => phase_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         (%Phase{}
          |> Phase.changeset(phase_params)
          |> validate_type_unique(socket.assigns.case))
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"phase" => phase_params},
        socket
      ) do
    true = authorized?(socket.assigns.case, :update, get_auth(socket))

    socket.assigns.case
    |> CaseContext.update_case(
      socket.assigns.case
      |> CaseContext.change_case()
      |> changeset_add_to_params(:phases, phase_params)
    )
    |> handle_save_response(socket, phase_params)
  end

  defp validate_type_unique(changeset, case) do
    case Ecto.Changeset.get_field(changeset, :details) do
      nil ->
        changeset

      %Phase.Index{} ->
        if Enum.find(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1)) do
          Ecto.Changeset.add_error(
            changeset,
            :type,
            gettext("Phase Type already exists on the case")
          )
        else
          changeset
        end

      %Phase.PossibleIndex{type: type} ->
        if Enum.find(case.phases, &match?(%Phase{details: %Phase.PossibleIndex{type: ^type}}, &1)) do
          Ecto.Changeset.add_error(
            changeset,
            :type,
            gettext("Phase Type already exists on the case")
          )
        else
          changeset
        end

      %Ecto.Changeset{} ->
        changeset
    end
  end

  defp handle_save_response({:ok, _case}, socket, _phase_params) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_phase_create_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("Phase created successfully")})

    {
      :noreply,
      socket
    }
  end

  defp handle_save_response({:error, _changeset}, socket, phase_params),
    do:
      {:noreply,
       socket
       |> assign(
         changeset: %{
           (%Phase{}
            |> Phase.changeset(phase_params)
            |> validate_type_unique(socket.assigns.case))
           | action: :insert
         }
       )
       |> maybe_block_navigation()}

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
