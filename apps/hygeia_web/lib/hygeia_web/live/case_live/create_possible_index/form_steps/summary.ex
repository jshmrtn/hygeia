defmodule HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.Summary do
  @moduledoc false

  use HygeiaWeb, :surface_live_component
  use Hygeia, :model

  import HygeiaGettext

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.PersonCard

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.FormSteps.{
    DefineTransmission,
    DefinePeople,
    DefineOptions,
    Reporting
  }

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Checkbox
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.Inputs

  prop form_step, :string, required: true
  prop live_action, :atom, required: true
  prop current_form_data, :keyword, required: true
  prop supervisor_users, :map, required: true
  prop tracer_users, :map, required: true

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       transmission_changeset: DefineTransmission.changeset(%DefineTransmission{}),
       people_changeset: DefinePeople.changeset(%DefinePeople{}),
       reporting_data: %{}
     )}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    transmission =
      assigns.current_form_data
      |> Keyword.get(DefineTransmission, %DefineTransmission{})

    people =
      assigns.current_form_data
      |> Keyword.get(DefinePeople, %DefinePeople{})

    reporting =
      assigns.current_form_data
      |> Keyword.get(Reporting, %Reporting{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:transmission_changeset, DefineTransmission.changeset(transmission))
     |> assign(:people_changeset, DefinePeople.changeset(people))
     |> assign(:reporting, reporting)}
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
