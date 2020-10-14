defmodule HygeiaApi.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias HygeiaApi.Schema.Dataloader, as: RepoDataLoader

  import_types AbsintheErrorPayload.ValidationMessageTypes

  @impl Absinthe.Schema
  @spec context(context :: map) :: map
  def context(context) do
    dataloader = Dataloader.add_source(Dataloader.new(), RepoDataLoader, RepoDataLoader.data())
    Map.put(context, :loader, dataloader)
  end

  @impl Absinthe.Schema
  @spec plugins :: [atom]
  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  node interface do
    resolve_type(fn _foo, _bar -> nil end)
  end

  query do
    @desc """
    Load Object by Global ID
    """

    node field do
      resolve(fn _foo, _bar -> {:ok, nil} end)
    end
  end
end
