defmodule HygeiaWeb.LiveView do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @impl Phoenix.LiveView
      def mount(_params, session, %{assigns: assigns} = socket) do
        import HygeiaWeb.Helpers.Auth

        HygeiaWeb.setup_live_view(session)

        {:ok,
         assign(
           socket,
           :__context__,
           assigns
           |> Map.get(:__context__, %{})
           |> Map.put({HygeiaWeb, :auth}, get_auth(socket))
           |> Map.put({HygeiaWeb, :logged_in}, is_logged_in?(socket))
         )}
      end

      @impl Phoenix.LiveView
      def handle_params(params, uri, %{assigns: assigns} = socket) do
        {:noreply,
         assign(
           socket,
           :__context__,
           assigns
           |> Map.get(:__context__, %{})
           |> Map.put({HygeiaWeb, :params}, params)
           |> Map.put({HygeiaWeb, :uri}, uri)
         )}
      end

      defoverridable mount: 3, handle_params: 3
    end
  end
end
