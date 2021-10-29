defmodule HygeiaWeb.AuthLive.Login do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.UserContext.User
  alias HygeiaWeb.Endpoint
  alias Phoenix.Token
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Link

  data person, :map
  data return_url, :string
  data form, :map, default: %{first_name: nil, last_name: nil}

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      assign(socket,
        return_url: params["return_url"] || Routes.home_index_path(socket, :index)
      )

    handle_login(socket, get_auth(socket), params["person_uuid"])
  end

  @impl Phoenix.LiveView
  def handle_event(
        "login",
        %{"person_login" => %{"first_name" => first_name, "last_name" => last_name}} = _params,
        socket
      ) do
    first_name_difference =
      String.jaro_distance(
        String.downcase(first_name),
        String.downcase(socket.assigns.person.first_name)
      )

    last_name_difference =
      String.jaro_distance(
        String.downcase(last_name),
        String.downcase(socket.assigns.person.last_name)
      )

    socket =
      if first_name_difference + last_name_difference >= 1.7 do
        push_redirect(socket,
          to:
            Routes.auth_path(socket, :request, "person",
              return_url: socket.assigns.return_url,
              uuid: Token.sign(Endpoint, "person auth", socket.assigns.person.uuid)
            )
        )
      else
        socket
        |> assign(form: %{first_name: first_name, last_name: last_name})
        |> put_flash(
          :error,
          gettext(
            "Invalid Person Details, if you believe this is an error, contact the tracing team."
          )
        )
      end

    {:noreply, socket}
  end

  defp handle_login(socket, %User{}, _person_uuid),
    do: {:ok, push_redirect(socket, to: socket.assigns.return_url)}

  defp handle_login(socket, _auth, nil),
    do:
      {:ok,
       push_redirect(socket,
         to: Routes.auth_path(socket, :request, "zitadel", return_url: socket.assigns.return_url)
       )}

  defp handle_login(socket, %Person{uuid: person_uuid}, person_uuid),
    do: {:ok, push_redirect(socket, to: socket.assigns.return_url)}

  defp handle_login(socket, _auth, person_uuid) when is_binary(person_uuid),
    do: {:ok, assign(socket, person: CaseContext.get_person!(person_uuid))}
end
