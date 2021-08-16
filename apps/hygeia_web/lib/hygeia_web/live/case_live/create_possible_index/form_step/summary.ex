defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Summary do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import HygeiaGettext

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard


  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Select

  alias Hygeia.CaseContext.Case.Status

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineTransmission
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.DefineOptions
  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormStep.Reporting

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :map, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("next", _, socket) do
    send(self(), :proceed)
    {:noreply, socket}
  end

  def handle_event("back", _, socket) do
    send(self(), :return)
    {:noreply, socket}
  end
end
