defmodule HygeiaWeb.PersonLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Surface.Components.Form.ErrorTag

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Inputs
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.Select
  alias Surface.Components.Form.TextInput

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    socket =
      if authorized?(Person, :create, get_auth(socket)) do
        tenants = TenantContext.list_tenants()

        assign(socket,
          changeset: CaseContext.change_person(%Person{}),
          tenants: tenants
        )
      else
        socket
        |> push_redirect(to: Routes.home_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    super(params, session, socket)
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"person" => person_params}, socket) do
    {:noreply,
     assign(socket, :changeset, %{
       CaseContext.change_person(%Person{}, person_params)
       | action: :validate
     })}
  end

  def handle_event("add_contact_method", _params, socket) do
    contact_methods = Ecto.Changeset.get_field(socket.assigns.changeset, :contact_methods, [])

    changeset =
      Ecto.Changeset.put_change(
        socket.assigns.changeset,
        :contact_methods,
        contact_methods ++ [%{}]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"person" => %{"tenant_uuid" => tenant_uuid} = person_params},
        %Phoenix.LiveView.Socket{assigns: %{tenants: tenants}} = socket
      ) do
    %Person{}
    |> CaseContext.change_person(person_params)
    |> Map.put(:action, :validate)
    |> case do
      %Ecto.Changeset{valid?: true} ->
        tenants
        |> Enum.find(&match?(%Tenant{uuid: ^tenant_uuid}, &1))
        |> CaseContext.create_person(person_params)
        |> case do
          {:ok, person} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Person created successfully"))
             |> push_redirect(to: Routes.person_base_data_path(socket, :show, person))}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      invalid_changeset ->
        {:noreply, assign(socket, :changeset, invalid_changeset)}
    end
  end

  defp load_people_by_id(ids) do
    CaseContext.list_people_by_ids(ids)
  end
end
