defmodule HygeiaWeb.CaseLive.Navigation do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Phase
  alias Hygeia.CaseContext.PossibleIndexSubmission
  alias Hygeia.CaseContext.Test
  alias Hygeia.OrganisationContext.Visit
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias HygeiaWeb.UriActiveContext
  alias Surface.Components.Link
  alias Surface.Components.LiveRedirect

  prop case, :map, required: true

  data note_modal, :map, default: nil
  data sms_modal, :map, default: nil
  data email_modal, :map, default: nil
  data phase_create_modal, :map, default: nil

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do:
      preload_assigns_one(
        assign_list,
        :case,
        &Repo.preload(&1, tenant: [], auto_tracing: [])
      )

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

    socket =
      if assigns[:__close_phase_create_modal__] do
        assign(socket, phase_create_modal: nil)
      else
        socket
      end

    assigns =
      Map.drop(assigns, [
        :__close_note_modal__,
        :__close_sms_modal__,
        :__close_email_modal__,
        :__close_phase_create_modal__
      ])

    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "delete",
        _params,
        %{assigns: %{case: %Case{person_uuid: person_uuid} = case}} = socket
      ) do
    true = authorized?(case, :delete, get_auth(socket))

    {:ok, _} = CaseContext.delete_case(case)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Case deleted successfully"))
     |> redirect(to: Routes.person_base_data_path(socket, :show, person_uuid))}
  end

  def handle_event("open_note_modal", params, socket) do
    {:noreply, assign(socket, note_modal: params)}
  end

  def handle_event("open_sms_modal", params, socket) do
    maybe_create_auto_tracing(socket.assigns.case, params["create_auto_tracing"])

    {:noreply, assign(socket, sms_modal: params)}
  end

  def handle_event("open_email_modal", params, socket) do
    maybe_create_auto_tracing(socket.assigns.case, params["create_auto_tracing"])

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

  def handle_event("open_phase_create_modal", params, socket) do
    {:noreply, assign(socket, phase_create_modal: params)}
  end

  def handle_event("close_phase_create_modal", _params, socket) do
    {:noreply, assign(socket, phase_create_modal: nil)}
  end

  defp has_index_phase?(case) do
    Enum.any?(case.phases, &match?(%Phase{details: %Phase.Index{}}, &1))
  end

  defp maybe_create_auto_tracing(case, enable)

  defp maybe_create_auto_tracing(%Case{auto_tracing: nil} = case, "true") do
    {:ok, _auto_tracing} = AutoTracingContext.create_auto_tracing(case)

    :ok
  end

  defp maybe_create_auto_tracing(_case, _enable), do: :ok
end
