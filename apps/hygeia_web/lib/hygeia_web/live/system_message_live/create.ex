defmodule HygeiaWeb.SystemMessageLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.SystemMessageContext
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.TenantContext
  alias Hygeia.UserContext.Grant.Role
  alias Surface.Components.Form
  alias Surface.Components.Form.DateTimeLocalInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.Form.TextArea

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      if authorized?(SystemMessage, :create, get_auth(socket)) do
        assign(socket, changeset: SystemMessageContext.change_system_message(%SystemMessage{}))
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"system_message" => system_message_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       SystemMessageContext.change_system_message(%SystemMessage{}, system_message_params)
       | action: :validate
     })}
  end

  def handle_event("save", %{"system_message" => system_message_params}, socket) do
    system_message_params
    |> SystemMessageContext.create_system_message()
    |> case do
      {:ok, system_message} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("System Message created succesfully"))
         |> push_redirect(to: Routes.system_message_show_path(socket, :show, system_message.uuid))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @spec roles :: [String.t()]
  def roles,
    do: Enum.map(Role.__enum_map__(), &{&1, &1})

  @spec tenants :: [{name :: String.t(), uuid :: String.t()}]
  def tenants,
    do:
      TenantContext.list_tenants()
      |> Enum.reject(&is_nil(&1.iam_domain))
      |> Enum.map(&{&1.name, &1.uuid})

  @spec get_text(changeset :: Ecto.Changeset.t()) :: text :: String.t()
  def get_text(%{changes: changes}) do
    case changes do
      %{text: text} -> text
      _other -> ""
    end
  end
end
