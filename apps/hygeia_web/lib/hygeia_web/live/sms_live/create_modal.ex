defmodule HygeiaWeb.SMSLive.CreateModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea

  data numbers, :list, default: []

  prop case, :map, required: true
  prop close, :event, required: true
  prop params, :map, default: %{}
  prop caller_id, :any, required: true
  prop caller_module, :atom, required: true

  @field_defaults %{"direction" => :outgoing, "status" => :in_progress}

  @impl Phoenix.LiveComponent
  def preload(assign_list),
    do: preload_assigns_one(assign_list, :case, &Repo.preload(&1, :person))

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    case = assigns.case || socket.assigns.case
    params = assigns.params || socket.assigns.params

    numbers =
      case.person.contact_methods
      |> Enum.filter(&match?(%ContactMethod{type: :mobile}, &1))
      |> Enum.map(& &1.value)

    changeset =
      case
      |> Ecto.build_assoc(:sms)
      |> CommunicationContext.change_sms(Map.merge(params, @field_defaults))

    {:ok, socket |> assign(assigns) |> assign(numbers: numbers, changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"sms" => sms_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         (socket.assigns.case
          |> Ecto.build_assoc(:sms)
          |> CommunicationContext.change_sms(Map.merge(sms_params, @field_defaults)))
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"sms" => sms_params},
        socket
      ) do
    true = authorized?(SMS, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> CommunicationContext.create_sms(Map.merge(sms_params, @field_defaults))
    |> handle_save_response(socket)
  end

  defp handle_save_response({:ok, _sms}, socket) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_sms_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("SMS created successfully")})

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
