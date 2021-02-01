defmodule HygeiaWeb.EmailLive.CreateModal do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  alias Hygeia.CaseContext.Person.ContactMethod
  alias Hygeia.CommunicationContext
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.Repo
  alias Surface.Components.Form
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.TextInput

  data emails, :list, default: []

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

    emails =
      case.person.contact_methods
      |> Enum.filter(&match?(%ContactMethod{type: :email}, &1))
      |> Enum.map(&{ContactMethod.name(&1), &1.value})

    changeset = CommunicationContext.change_email_create(case, Map.merge(params, @field_defaults))

    {:ok, socket |> assign(assigns) |> assign(emails: emails, changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"email" => email_params}, socket) do
    {:noreply,
     socket
     |> assign(
       changeset: %{
         CommunicationContext.change_email_create(
           socket.assigns.case,
           Map.merge(email_params, @field_defaults)
         )
         | action: :validate
       }
     )
     |> maybe_block_navigation()}
  end

  def handle_event(
        "save",
        %{"email" => email_params},
        socket
      ) do
    true = authorized?(Email, :create, get_auth(socket), %{case: socket.assigns.case})

    socket.assigns.case
    |> CommunicationContext.create_email(Map.merge(email_params, @field_defaults))
    |> handle_save_response(socket)
  end

  defp handle_save_response({:ok, _email}, socket) do
    send_update(socket.assigns.caller_module,
      id: socket.assigns.caller_id,
      __close_email_modal__: true
    )

    send(self(), {:put_flash, :info, gettext("Email created successfully")})

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
