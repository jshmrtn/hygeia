defmodule HygeiaWeb.LiveView do
  @moduledoc false

  import HygeiaWeb.Helpers.Auth

  import Phoenix.LiveView,
    only: [assign: 3, get_connect_params: 1, connected?: 1, get_connect_info: 1]

  alias Phoenix.LiveView.Socket

  defmacro __using__(opts \\ []) do
    quote location: :keep, bind_quoted: [opts: opts] do
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

    assign(
      socket,
      :__context__,
      socket.assigns
      |> Map.get(:__context__, %{})
      |> Map.put({HygeiaWeb, :auth}, get_auth(socket))
      |> Map.put({HygeiaWeb, :logged_in}, is_logged_in?(socket))
      |> Map.put(
        {HygeiaWeb, :browser_features},
        if(connected?(socket) and not is_nil(socket.private[:connect_params]),
          do: get_connect_params(socket)["browser_features"]
        )
      )
      |> Map.put(
        {HygeiaWeb, :ip_address},
        if(connected?(socket) and not is_nil(socket.private[:connect_info]),
          do: get_ip_address(socket)
        )
      )
    )
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
  def before_handle_params(socket, params, uri) do
    assign(
      socket,
      :__context__,
      socket.assigns
      |> Map.get(:__context__, %{})
      |> Map.put({HygeiaWeb, :params}, params)
      |> Map.put({HygeiaWeb, :uri}, uri)
    )
  end
end
