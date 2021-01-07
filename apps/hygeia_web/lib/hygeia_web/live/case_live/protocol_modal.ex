defmodule HygeiaWeb.CaseLive.ProtocolModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.ProtocolEntry
  alias HygeiaWeb.PolimorphicInputs
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext

  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  prop case, :map, required: true
  prop close, :event, required: true
  prop params, :map, default: %{}
  prop caller_id, :any, required: true
  prop caller_module, :atom, required: true

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    case = assigns.case || socket.assigns.case
    params = assigns.params || socket.assigns.params

    changeset =
      case |> Ecto.build_assoc(:protocol_entries) |> CaseContext.change_protocol_entry(params)

    {:ok, socket |> assign(assigns) |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"protocol_entry" => protocol_entry_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         (socket.assigns.case
          |> Ecto.build_assoc(:protocol_entries)
          |> CaseContext.change_protocol_entry(protocol_entry_params))
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"protocol_entry" => %{"type" => type} = protocol_entry_params},
        socket
      )
      when not (type in ["email", "sms"]) do
    true = authorized?(ProtocolEntry, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> CaseContext.create_protocol_entry(protocol_entry_params)
    |> handle_save_response(socket)
  end

  def handle_event(
        "save",
        %{"protocol_entry" => %{"type" => "email"} = protocol_entry_params},
        socket
      ) do
    true = authorized?(ProtocolEntry, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> Ecto.build_assoc(:protocol_entries)
    |> CaseContext.change_protocol_entry(protocol_entry_params)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        CaseContext.case_send_email(
          socket.assigns.case,
          Ecto.Changeset.fetch_field!(changeset, :entry).subject,
          Ecto.Changeset.fetch_field!(changeset, :entry).body
        )

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}
    end
    |> handle_save_response(socket)
  end

  def handle_event(
        "save",
        %{"protocol_entry" => %{"type" => "sms"} = protocol_entry_params},
        socket
      ) do
    true = authorized?(ProtocolEntry, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> Ecto.build_assoc(:protocol_entries)
    |> CaseContext.change_protocol_entry(
      Map.update(
        protocol_entry_params,
        "entry",
        %{"delivery_receipt_id" => "empty"},
        &Map.put(&1, "delivery_receipt_id", "empty")
      )
    )
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        CaseContext.case_send_sms(
          socket.assigns.case,
          Ecto.Changeset.fetch_field!(changeset, :entry).text
        )

      %Ecto.Changeset{valid?: false} = changeset ->
        {:error, changeset}
    end
    |> handle_save_response(socket)
  end

  defp handle_save_response({:ok, _protocol_entry}, socket) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_protocol_entry_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("Protocol Entry created successfully")})

    {
      :noreply,
      socket
    }
  end

  defp handle_save_response({:error, %Ecto.Changeset{} = changeset}, socket),
    do:
      {:noreply,
       socket
       |> assign(changeset: changeset)
       |> maybe_block_navigation()}

  defp maybe_block_navigation(%{assigns: %{changeset: %{changes: changes}}} = socket) do
    if changes == %{} do
      push_event(socket, "unblock_navigation", %{})
    else
      push_event(socket, "block_navigation", %{})
    end
  end
end
