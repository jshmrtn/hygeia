defmodule HygeiaWeb.CaseLive.Protocol do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Note
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.Repo
  alias Hygeia.VersionContext.Version
  alias Mail.Message
  alias Mail.Parsers.RFC2822
  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, now: DateTime.utc_now())

    :timer.send_interval(:timer.seconds(1), :tick)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = _params, _uri, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(case, :details, get_auth(socket)) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "notes:case:#{id}")
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "sms:case:#{id}")
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "emails:case:#{id}")

        load_data(socket, case)
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info({:put_flash, type, msg}, socket), do: {:noreply, put_flash(socket, type, msg)}

  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply, load_data(socket, case)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info({_event, %Note{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info({_event, %SMS{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info({_event, %Email{}, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, case) do
    case = Repo.preload(case, person: [tenant: []], tenant: [])

    assign(socket,
      case: case,
      protocol_entries: CaseContext.list_protocol_entries(case),
      page_title:
        "#{case.person.first_name} #{case.person.last_name} - #{gettext("Protocol")} - #{gettext("Case")}"
    )
  end
end
