defmodule HygeiaWeb.AutoTracingLive.ContactMethods do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.Helpers.Empty
  alias Hygeia.Repo

  alias Surface.Components.Form
  alias Surface.Components.Form.EmailInput
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.TelephoneInput

  @impl Phoenix.LiveView
  def handle_params(%{"case_uuid" => case_uuid} = _params, _uri, socket) do
    case =
      case_uuid
      |> CaseContext.get_case!()
      |> Repo.preload(person: [], auto_tracing: [])

    socket =
      if authorized?(case, :auto_tracing, get_auth(socket)) do
        contact_methods = get_contact_methods(case.person)

        {:ok, auto_tracing} =
          AutoTracingContext.update_auto_tracing(case.auto_tracing, contact_methods)

        person_changeset =
          case contact_methods do
            %{email: nil, mobile: nil, landline: nil} ->
              %{CaseContext.change_person(case.person) | valid?: false}

            _other ->
              CaseContext.change_person(case.person)
          end

        assign(socket,
          case: case,
          person: case.person,
          person_changeset: person_changeset,
          auto_tracing: auto_tracing,
          auto_tracing_changeset: AutoTracingContext.change_auto_tracing(auto_tracing)
        )
      else
        push_redirect(socket,
          to:
            Routes.auth_login_path(socket, :login,
              person_uuid: case.person_uuid,
              return_url: Routes.auto_tracing_auto_tracing_path(socket, :auto_tracing, case)
            )
        )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "validate",
        %{"auto_tracing" => %{"email" => email, "landline" => landline, "mobile" => mobile}},
        socket
      ) do
    socket =
      assign(socket, :auto_tracing_changeset, %{
        AutoTracingContext.change_auto_tracing(socket.assigns.auto_tracing, %{
          email: email,
          landline: landline,
          mobile: mobile
        })
        | action: :validate
      })

    socket =
      if socket.assigns.auto_tracing_changeset.valid? and
           (not is_nil(socket.assigns.auto_tracing_changeset.data.email) or
              not is_nil(socket.assigns.auto_tracing_changeset.data.landline) or
              not is_nil(socket.assigns.auto_tracing_changeset.data.mobile) or
              not Empty.is_empty?(socket.assigns.auto_tracing_changeset, [])) do
        [contact_methods] =
          socket.assigns.auto_tracing_changeset.changes
          |> Map.to_list()
          |> Enum.map(fn {k, v} -> %{type: k, value: v, uuid: Ecto.UUID.generate()} end)
          |> Enum.reduce([], fn contact_method, acc ->
            [
              changeset_add_to_params(
                socket.assigns.person_changeset,
                :contact_methods,
                contact_method
              )
              | acc
            ]
          end)

        assign(
          socket,
          :person_changeset,
          CaseContext.change_person(socket.assigns.person, contact_methods)
        )
      else
        assign(socket, :person_changeset, %{socket.assigns.person_changeset | valid?: false})
      end

    {:noreply, socket}
  end

  def handle_event("advance", _params, socket) do
    if not Empty.is_empty?(socket.assigns.auto_tracing_changeset, []) do
      CaseContext.update_person(socket.assigns.person_changeset)
    end

    {:ok, _auto_tracing} =
      AutoTracingContext.advance_one_step(socket.assigns.auto_tracing, :contact_methods)

    {:noreply,
     push_redirect(socket,
       to:
         Routes.auto_tracing_employer_path(
           socket,
           :employer,
           socket.assigns.auto_tracing.case_uuid
         )
     )}
  end

  defp get_contact_methods(person) do
    email =
      Enum.find_value(person.contact_methods, fn
        %{type: :email, value: value} -> value
        _contact_method -> false
      end)

    mobile =
      Enum.find_value(person.contact_methods, fn
        %{type: :mobile, value: value} -> value
        _contact_method -> false
      end)

    landline =
      Enum.find_value(person.contact_methods, fn
        %{type: :landline, value: value} -> value
        _contact_method -> false
      end)

    %{email: email, mobile: mobile, landline: landline}
  end
end
