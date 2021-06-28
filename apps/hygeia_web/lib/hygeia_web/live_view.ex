defmodule HygeiaWeb.LiveView do
  @moduledoc false

  import HygeiaWeb.Helpers.Auth

  import Phoenix.LiveView,
    only: [assign: 3, get_connect_params: 1, connected?: 1, get_connect_info: 1]

  alias Hygeia.EctoType.LocalizedNaiveDatetime
  alias Phoenix.LiveView.Socket

  @default_timezone "Europe/Zurich"

  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import HygeiaWeb.LiveView, only: [context_get: 3, context_get: 2]

      enabled_transforms = Keyword.get(opts, :only, [:mount, :handle_params])

      if Enum.member?(enabled_transforms, :mount) do
        @before_compile {HygeiaWeb.LiveView, :__before_compile_mount__}
      end

      if Enum.member?(enabled_transforms, :handle_params) do
        @before_compile {HygeiaWeb.LiveView, :__before_compile_handle_params__}
      end
    end
  end

  defmacro __before_compile_mount__(env) do
    if Module.defines?(env.module, {:mount, 3}) do
      quote location: :keep do
        defoverridable mount: 3

        @impl Phoenix.LiveView
        def mount(params, session, socket) do
          socket = HygeiaWeb.LiveView.before_mount(socket, session)

          super(params, session, socket)
        end
      end
    else
      quote location: :keep do
        @impl Phoenix.LiveView
        def mount(_params, session, socket) do
          {:ok, HygeiaWeb.LiveView.before_mount(socket, session)}
        end
      end
    end
  end

  defmacro __before_compile_handle_params__(env) do
    if Module.defines?(env.module, {:handle_params, 3}) do
      quote location: :keep do
        defoverridable handle_params: 3

        @impl Phoenix.LiveView
        def handle_params(params, uri, socket) do
          socket = HygeiaWeb.LiveView.before_handle_params(socket, params, uri)

          super(params, uri, socket)
        end
      end
    else
      quote location: :keep do
        @impl Phoenix.LiveView
        def handle_params(params, uri, socket) do
          {:noreply, HygeiaWeb.LiveView.before_handle_params(socket, params, uri)}
        end
      end
    end
  end

  @doc false
  @spec before_mount(socket :: Socket.t(), session :: map) :: Socket.t()
  def before_mount(socket, session) do
    HygeiaWeb.setup_live_view(session)

    timezone =
      with true <- connected?(socket),
           %{} <- socket.private[:connect_params],
           %{"timezone" => timezone} <- get_connect_params(socket),
           true <- Tzdata.zone_exists?(timezone) do
        timezone
      else
        false -> @default_timezone
        nil -> @default_timezone
        %{} -> @default_timezone
      end

    :ok = LocalizedNaiveDatetime.put_timezone(timezone)

    socket
    |> context_assign(:auth, get_auth(socket))
    |> context_assign(:logged_in, is_logged_in?(socket))
    |> context_assign(
      :browser_features,
      if connected?(socket) and not is_nil(socket.private[:connect_params]) do
        get_connect_params(socket)["browser_features"]
      end
    )
    |> context_assign(
      :ip_address,
      if connected?(socket) and not is_nil(socket.private[:connect_info]) do
        get_ip_address(socket)
      end
    )
    |> context_assign(
      :uri,
      case {socket.host_uri, socket.private[:connect_info][:uri]} do
        {%URI{} = uri, _connect_uri} -> URI.to_string(uri)
        {:not_mounted_at_router, %URI{} = uri} -> URI.to_string(uri)
        _other -> nil
      end
    )
    |> context_assign(:timezone, timezone)
  end

  defp get_ip_address(socket) do
    case get_connect_info(socket) do
      %{peer_data: peer_data} ->
        peer_data.address

      _other ->
        nil
    end
  end

  @doc false
  @spec before_handle_params(socket :: Socket.t(), params :: map, uri :: String.t()) :: Socket.t()
  def before_handle_params(socket, params, uri),
    do:
      socket
      |> context_assign(:params, params)
      |> context_assign(:uri, uri)

  defp context_assign(socket, key, value),
    do:
      assign(
        socket,
        :__context__,
        socket.assigns
        |> Map.get(:__context__, %{})
        |> Map.put({HygeiaWeb, key}, value)
      )

  @spec context_get(socket :: Socket.t(), key :: atom, default :: default) :: term | default
        when default: term
  def context_get(socket, key, default \\ nil)

  def context_get(%Socket{assigns: %{__context__: context}}, key, default) do
    context
    |> Map.fetch({HygeiaWeb, key})
    |> case do
      :error -> default
      {:ok, value} -> value
    end
  end

  def context_get(_socket, _key, default), do: default
end
