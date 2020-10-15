defmodule HygeiaWeb.PersonLive.FormComponent do
  @moduledoc false

  use HygeiaWeb, :live_component

  alias Hygeia.CaseContext
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @impl Phoenix.LiveComponent
  def update(%{person: person} = assigns, socket) do
    changeset = CaseContext.change_person(person)
    tenants = TenantContext.list_tenants()
    professions = CaseContext.list_professions()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:tenants, tenants)
     |> assign(:professions, professions)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"person" => person_params}, socket) do
    changeset =
      socket.assigns.person
      |> CaseContext.change_person(person_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"person" => person_params}, socket) do
    save_person(socket, socket.assigns.action, person_params)
  end

  defp save_person(socket, :edit, person_params) do
    case CaseContext.update_person(socket.assigns.person, person_params) do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Person updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_person(
         %Phoenix.LiveView.Socket{assigns: %{tenants: tenants}} = socket,
         :new,
         %{"tenant_uuid" => tenant_uuid} = person_params
       ) do
    tenants
    |> Enum.find(&match?(%Tenant{uuid: ^tenant_uuid}, &1))
    |> CaseContext.create_person(person_params)
    |> case do
      {:ok, _person} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Person created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp countries do
    locale = HygeiaWeb.Cldr.get_locale().language

    Enum.map(
      Cadastre.Country.ids(),
      &{&1 |> Cadastre.Country.new() |> Cadastre.Country.name(locale), &1}
    )
  end

  defp subdivisions(changeset) do
    locale = HygeiaWeb.Cldr.get_locale().language

    changeset
    |> Ecto.Changeset.fetch_field!(:country)
    |> case do
      nil ->
        []

      country ->
        Enum.map(
          Cadastre.Subdivision.all(country),
          &{Cadastre.Subdivision.name(&1, locale), &1.id}
        )
    end
  end
end
