defmodule HygeiaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use HygeiaWeb, :controller
      use HygeiaWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  import Phoenix.LiveView, only: [assign: 3]

  alias Phoenix.LiveView.Socket

  @doc false
  @spec controller :: Macro.t()
  def controller do
    quote location: :keep do
      use Phoenix.Controller, namespace: HygeiaWeb

      import Plug.Conn
      import HygeiaGettext
      import Hygeia.Authorization
      import HygeiaWeb.Helpers.Auth

      alias HygeiaWeb.Router.Helpers, as: Routes
    end
  end

  @doc false
  @spec view :: Macro.t()
  def view do
    quote location: :keep do
      use Phoenix.View,
        root: "lib/hygeia_web/templates",
        namespace: HygeiaWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  @doc false
  @spec live_view :: Macro.t()
  def live_view do
    quote location: :keep do
      use Phoenix.LiveView,
        layout: {HygeiaWeb.LayoutView, "live.html"}

      import HygeiaWeb, only: [context_get: 3, context_get: 2]

      on_mount(HygeiaWeb.Init.Auth)
      on_mount(HygeiaWeb.Init.Context)
      on_mount(HygeiaWeb.Init.Locale)

      unquote(view_helpers())
    end
  end

  @doc false
  @spec surface_view :: Macro.t()
  def surface_view do
    quote location: :keep do
      use Surface.LiveView,
        layout: {HygeiaWeb.LayoutView, "live.html"}

      import HygeiaWeb, only: [context_get: 3, context_get: 2]

      on_mount(HygeiaWeb.Init.Auth)
      on_mount(HygeiaWeb.Init.Context)
      on_mount(HygeiaWeb.Init.Locale)

      unquote(view_helpers())
    end
  end

  @spec surface_view_bare :: Macro.t()
  def surface_view_bare do
    quote location: :keep do
      use Surface.LiveView,
        layout: {HygeiaWeb.LayoutView, "live.html"}

      import HygeiaWeb, only: [context_get: 3, context_get: 2]

      on_mount(HygeiaWeb.Init.Auth)
      on_mount(HygeiaWeb.Init.Context)
      on_mount(HygeiaWeb.Init.Locale)

      unquote(view_helpers())
    end
  end

  @doc false
  @spec live_component :: Macro.t()
  def live_component do
    quote location: :keep do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  @doc false
  @spec surface_live_component :: Macro.t()
  def surface_live_component do
    quote location: :keep do
      use Surface.LiveComponent

      unquote(view_helpers())
    end
  end

  @doc false
  @spec surface_component :: Macro.t()
  def surface_component do
    quote location: :keep do
      use Surface.Component

      unquote(view_helpers())
    end
  end

  @doc false
  @spec router :: Macro.t()
  def router do
    quote location: :keep do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @doc false
  @spec channel :: Macro.t()
  def channel do
    quote location: :keep do
      use Phoenix.Channel
      import HygeiaGettext
    end
  end

  defp view_helpers do
    quote location: :keep do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import HygeiaGettext

      import Hygeia.Authorization

      import HygeiaWeb.ErrorHelpers
      import HygeiaWeb.Helpers.Address
      import HygeiaWeb.Helpers.Auth
      import HygeiaWeb.Helpers.Case
      import HygeiaWeb.Helpers.Changeset
      import HygeiaWeb.Helpers.Clinical
      import HygeiaWeb.Helpers.Communication
      import HygeiaWeb.Helpers.Confirmation
      import HygeiaWeb.Helpers.CSP
      import HygeiaWeb.Helpers.FieldName
      import HygeiaWeb.Helpers.Import
      import HygeiaWeb.Helpers.InfectionPlace
      import HygeiaWeb.Helpers.Monitoring
      import HygeiaWeb.Helpers.Organisation
      import HygeiaWeb.Helpers.Person
      import HygeiaWeb.Helpers.Preload
      import HygeiaWeb.Helpers.Region
      import HygeiaWeb.Helpers.Search
      import HygeiaWeb.Helpers.Versioning

      import PhoenixActiveLink

      alias HygeiaWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @spec context_assign(socket :: Socket.t(), key :: atom, value :: term) :: Socket.t()
  def context_assign(socket, key, value),
    do:
      assign(
        socket,
        :__context__,
        socket.assigns
        |> Map.get(:__context__, %{})
        |> Map.put({__MODULE__, key}, value)
      )

  @spec context_get(socket :: Socket.t(), key :: atom, default :: default) :: term | default
        when default: term
  def context_get(socket, key, default \\ nil)

  def context_get(%Socket{assigns: %{__context__: context}}, key, default) do
    context
    |> Map.fetch({__MODULE__, key})
    |> case do
      :error -> default
      {:ok, value} -> value
    end
  end

  def context_get(_socket, _key, default), do: default
end
