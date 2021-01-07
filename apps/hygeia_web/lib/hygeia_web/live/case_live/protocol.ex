defmodule HygeiaWeb.CaseLive.Protocol do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.ProtocolEntry
  alias Hygeia.Repo
  alias PaperTrail.Version
  alias Surface.Components.Link

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket = assign(socket, now: DateTime.utc_now())

    :timer.send_interval(:timer.seconds(1), :tick)

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = params, uri, socket) do
    case = CaseContext.get_case!(id)

    socket =
      if authorized?(
           case,
           case socket.assigns.live_action do
             :edit -> :update
             :show -> :details
           end,
           get_auth(socket)
         ) do
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "cases:#{id}")
        Phoenix.PubSub.subscribe(Hygeia.PubSub, "protocol_entries:case:#{id}")

        socket
        |> assign(modal_open: Map.drop(params, ["id"]) != %{})
        |> load_data(case)
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, uri, socket)
  end

  @impl Phoenix.LiveView
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_info({:put_flash, type, msg}, socket), do: {:noreply, put_flash(socket, type, msg)}

  def handle_info({_action, %ProtocolEntry{} = _protocol_entry, _version}, socket) do
    {:noreply, load_data(socket, CaseContext.get_case!(socket.assigns.case.uuid))}
  end

  def handle_info({:updated, %Case{} = case, _version}, socket) do
    {:noreply, load_data(socket, case)}
  end

  def handle_info({:deleted, %Case{}, _version}, socket) do
    {:noreply, redirect(socket, to: Routes.case_index_path(socket, :index))}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  defp load_data(socket, case) do
    case = Repo.preload(case, protocol_entries: [], person: [tenant: []], tenant: [])
    assign(socket, case: case)
  end

  defp get_protocol_user(protocol_entry) do
    protocol_entry |> PaperTrail.get_version() |> Repo.preload(:user) |> Map.fetch!(:user)
  end

  defp get_protocol_origin(protocol_entry) do
    protocol_entry |> PaperTrail.get_version() |> Map.fetch!(:origin) |> String.to_existing_atom()
  end

  defp protocol_type_type_name(Hygeia.CaseContext.ProtocolEntry.Note), do: gettext("Note")
  defp protocol_type_type_name(Hygeia.CaseContext.ProtocolEntry.Email), do: gettext("Email")
  defp protocol_type_type_name(Hygeia.CaseContext.ProtocolEntry.Sms), do: gettext("SMS")
end
