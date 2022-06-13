defmodule HygeiaWeb.AuthLive.Login do
  @moduledoc false

  use HygeiaWeb, :surface_view

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person
  alias Hygeia.LoginRateLimiter
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
  data login_disabled, :boolean, default: false
  data login_lock_remaining, :number, default: 0
  data login_lock_remaining_interval, :any

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket =
      assign(socket,
        return_url: params["return_url"] || Routes.home_index_path(socket, :index),
        login_disabled: false
      )

    handle_login(socket, get_auth(socket), params["person_uuid"])
  end

  @impl Phoenix.LiveView
  def handle_event(
        "login",
        %{"person_login" => %{"first_name" => first_name, "last_name" => last_name}} = _params,
        socket
      ) do
    {:ok, socket} =
      LoginRateLimiter.handle_login(socket.assigns.person.uuid, fn ->
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

        success = first_name_difference + last_name_difference >= 1.7

        socket =
          cond do
            success ->
              push_redirect(socket,
                to:
                  Routes.auth_path(socket, :request, "person",
                    return_url: socket.assigns.return_url,
                    uuid: Token.sign(Endpoint, "person auth", socket.assigns.person.uuid)
                  )
              )

            String.length(first_name) < 2 and String.length(last_name) < 2 ->
              socket
              |> assign(form: %{first_name: first_name, last_name: last_name})
              |> put_flash(:error, gettext("Please enter a full name."))

            true ->
              socket
              |> assign(login_disabled: true)
              |> assign(form: %{first_name: first_name, last_name: last_name})
              |> put_flash(
                :error,
                gettext(
                  "Invalid Person Details, if you believe this is an error, contact the tracing team."
                )
              )
          end

        {success, socket}
      end)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(:unlock, socket) do
    case socket.assigns[:login_lock_remaining_interval] do
      nil ->
        nil

      login_lock_remaining_interval ->
        {:ok, :cancel} = :timer.cancel(login_lock_remaining_interval)
    end

    {:noreply, assign(socket, login_disabled: false, login_lock_remaining: 0)}
  end

  def handle_info({:lock, time}, socket) do
    {:ok, timer} = :timer.send_interval(100, :decrease_login_lock_remaining)

    {:noreply,
     assign(socket,
       login_disabled: true,
       login_lock_remaining: time,
       login_lock_remaining_interval: timer
     )}
  end

  def handle_info(:decrease_login_lock_remaining, socket),
    do:
      {:noreply,
       assign(socket, login_lock_remaining: max(socket.assigns.login_lock_remaining - 100, 0))}

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

  defp handle_login(socket, _auth, person_uuid) when is_binary(person_uuid) do
    Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

    {:ok,
     assign(socket,
       person: CaseContext.get_person!(person_uuid),
       login_disabled: LoginRateLimiter.locked?(person_uuid),
       login_lock_remaining: 0
     )}
  end

  defp format_remaining_time(time) do
    (trunc(time / 1000) + 1)
    |> Cldr.Unit.new!(:second)
    |> Cldr.Unit.localize(HygeiaCldr, [])
    |> HygeiaCldr.Unit.to_string!(format: :short, style: :short)
  end
end
