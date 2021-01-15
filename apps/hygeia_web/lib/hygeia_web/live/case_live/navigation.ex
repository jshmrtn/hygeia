defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.TenantContext
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true
  data note_modal, :map, default: nil
  data sms_modal, :map, default: nil
  data email_modal, :map, default: nil

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      if assigns[:__close_note_modal__] do
        assign(socket, note_modal: nil)
      else
        socket
      end

    socket =
      if assigns[:__close_sms_modal__] do
        assign(socket, sms_modal: nil)
      else
        socket
      end

    socket =
      if assigns[:__close_email_modal__] do
        assign(socket, email_modal: nil)
      else
        socket
      end

    assigns =
      Map.drop(assigns, [:__close_note_modal__, :__close_sms_modal__, :__close_email_modal__])

    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "convert_to_index",
        _params,
        %{assigns: %{case: %Case{phases: phases} = case}} = socket
      ) do
    true = authorized?(case, :update, get_auth(socket))

    index_last = length(phases) - 1

    phase_args =
      phases
      |> Enum.with_index()
      |> Enum.map(fn
        {phase, ^index_last} ->
          %{
            uuid: phase.uuid,
            details: %{end_reason: :converted_to_index},
            end: Date.utc_today(),
            send_automated_close_email: false
          }

        {phase, _other_index} ->
          %{uuid: phase.uuid}
      end)
      |> Kernel.++([%{start: Date.utc_today(), details: %{__type__: :index}}])

    {:ok, case} = CaseContext.update_case(case, %{phases: phase_args})

    {:noreply,
     socket
     |> push_redirect(to: Routes.case_base_data_path(socket, :show, case))
     |> put_flash(:info, gettext("Created Index Phase"))}
  end

  def handle_event("delete", _params, %{assigns: %{case: case}} = socket) do
    true = authorized?(case, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_case(case)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Case deleted successfully"))
     |> redirect(to: Routes.case_index_path(socket, :index))}
  end

  def handle_event("open_note_modal", params, socket) do
    {:noreply, assign(socket, note_modal: params)}
  end

  def handle_event("open_sms_modal", params, socket) do
    {:noreply, assign(socket, sms_modal: params)}
  end

  def handle_event("open_email_modal", params, socket) do
    {:noreply, assign(socket, email_modal: params)}
  end

  def handle_event("close_note_modal", _params, socket) do
    {:noreply, assign(socket, note_modal: nil)}
  end

  def handle_event("close_sms_modal", _params, socket) do
    {:noreply, assign(socket, sms_modal: nil)}
  end

  def handle_event("close_email_modal", _params, socket) do
    {:noreply, assign(socket, email_modal: nil)}
  end

  defp can_generate_isolation_confirmation(phase) do
    phase.start != nil and phase.end != nil
  end

  defp can_generate_quarantine_confirmation(phase) do
    phase.details.type == :contact_person and phase.start != nil and phase.end != nil
  end

  defp has_index_phase?(case) do
    Enum.any?(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1))
  end
end
