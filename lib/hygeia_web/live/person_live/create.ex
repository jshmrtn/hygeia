defmodule HygeiaWeb.PersonLive.Create do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      if authorized?(Person, :create, get_auth(socket), tenant: :any) do
        assign(socket,
          changeset: CaseContext.change_person(%Person{}, params),
          page_title: gettext("New Person"),
          tenants:
            Enum.filter(
              TenantContext.list_tenants(),
              &authorized?(Person, :create, get_auth(socket), tenant: &1)
            )
        )
      else
        socket
        |> push_redirect(to: Routes.home_index_path(socket, :index))
        |> put_flash(:error, gettext("You are not authorized to do this action."))
      end

    {:ok, socket}
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
    {:noreply,
     assign(
       socket,
       :changeset,
       CaseContext.change_person(
         %Person{},
         changeset_add_to_params(socket.assigns.changeset, :contact_methods, %{
           uuid: Ecto.UUID.generate()
         })
       )
     )}
  end

  def handle_event("remove_contact_method", %{"uuid" => contact_method_uuid}, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       CaseContext.change_person(
         %Person{},
         changeset_remove_from_params_by_id(socket.assigns.changeset, :contact_methods, %{
           uuid: contact_method_uuid
         })
       )
     )}
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
end
