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

  alias Hygeia.Helpers.Versioning

  def controller do
    quote do
      use Phoenix.Controller, namespace: HygeiaWeb

      import Plug.Conn
      import HygeiaWeb.Gettext

      alias HygeiaWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
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

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {HygeiaWeb.LayoutView, "live.html"}

      unquote(view_helpers())

      @impl Phoenix.LiveView
      def mount(_params, session, socket) do
        HygeiaWeb.setup_live_view(session)

        {:ok, socket}
      end

      defoverridable mount: 3
    end
  end

  def surface_view do
    quote do
      use Surface.LiveView,
        layout: {HygeiaWeb.LayoutView, "live.html"}

      unquote(view_helpers())

      @impl Phoenix.LiveView
      def mount(_params, session, socket) do
        HygeiaWeb.setup_live_view(session)

        {:ok, socket}
      end

      defoverridable mount: 3
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def surface_live_component do
    quote do
      use Surface.LiveComponent

      unquote(view_helpers())
    end
  end

  def surface_component do
    quote do
      use Surface.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import HygeiaWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import HygeiaWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import HygeiaWeb.ErrorHelpers
      import HygeiaWeb.Gettext

      import HygeiaWeb.Helpers.Address
      import HygeiaWeb.Helpers.Case
      import HygeiaWeb.Helpers.ContactMethod
      import HygeiaWeb.Helpers.ExternalReference
      import HygeiaWeb.Helpers.Phase
      import HygeiaWeb.Helpers.Region

      import PhoenixActiveLink

      alias HygeiaWeb.Router.Helpers, as: Routes
    end
  end

  @doc false
  @spec setup_live_view(session :: map) :: :ok
  def setup_live_view(session) do
    unless is_nil(session["cldr_locale"]) do
      HygeiaWeb.Cldr.put_locale(session["cldr_locale"])
      Gettext.put_locale(HygeiaWeb.Cldr.get_locale().gettext_locale_name)
    end

    Versioning.put_origin(:web)

    unless is_nil(session["auth"]) do
      Versioning.put_originator(session["auth"])
    end

    :ok
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
