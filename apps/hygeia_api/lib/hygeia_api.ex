defmodule HygeiaApi do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use HygeiaApi, :controller
      use HygeiaApi, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: HygeiaApi

      import Plug.Conn
      alias HygeiaApi.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/hygeia_api_web/templates",
        namespace: HygeiaApi

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  defp view_helpers do
    quote do
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import HygeiaApi.ErrorHelpers
      alias HygeiaApi.Router.Helpers, as: Routes
    end
  end

  def subschema do
    quote do
      use Absinthe.Schema.Notation
      use Absinthe.Relay.Schema.Notation, :modern

      import Absinthe.Resolution.Helpers, only: [dataloader: 1]

      import AbsintheErrorPayload.Payload

      import HygeiaApi.Schema.DynamicEnum
      import HygeiaApi.Schema.PayloadHelper

      alias HygeiaApi.Middleware.CheckPermission
      alias HygeiaApi.Middleware.TranslateContent
      alias HygeiaApi.Schema.Dataloader, as: RepoDataLoader

      alias __MODULE__.Resolver
      alias __MODULE__.SubscriptionConfig
      alias __MODULE__.SubscriptionTriggerTopic
    end
  end

  def resolver do
    quote do
      import HygeiaApi.Authorization
      import HygeiaApi.Schema.Result

      import Ecto.Query

      import Absinthe.Resolution.Helpers
      import HygeiaApi.Helpers
    end
  end

  def subscription_config do
    quote do
      @type config_result ::
              {:ok, [{:topic, term | [term]}, {:context_id, term}]} | {:error, term}

      import unquote(__MODULE__), only: [from_global_id!: 2]

      alias unquote(__MODULE__).InvalidIdError
    end
  end

  def subscription_trigger_topic do
    quote do
    end
  end

  defmodule InvalidIdError do
    @moduledoc false

    defexception [:message]
  end

  @spec from_global_id!(id :: String.t(), type :: atom) :: String.t()
  def from_global_id!(id, type) when is_atom(type) do
    %{id: id} = from_global_id!(id, [type])
    id
  end

  @spec from_global_id!(id :: String.t(), types :: [atom]) :: %{type: atom(), id: binary()}
  def from_global_id!(id, types) when is_list(types) do
    id
    |> Absinthe.Relay.Node.from_global_id(HygeiaApi.Schema)
    |> case do
      {:ok, %{type: type} = id_map} ->
        unless type in types do
          raise InvalidIdError, message: "Invalid ID Type"
        end

        id_map

      {:error, _reason} ->
        raise InvalidIdError, message: "Invalid ID"
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
