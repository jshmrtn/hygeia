defmodule Hygeia.Helpers.PubSub do
  @moduledoc false

  @spec broadcast(
          result ::
            {:ok, %{model: resource, version: %PaperTrail.Version{}}}
            | {:error, reason},
          resource_name :: String.t(),
          action :: :create | :update | :delete,
          id_fetcher :: (resource -> String.t())
        ) :: {:ok, resource} | {:error, reason}
        when resource: term, reason: term
  def broadcast(result, resource_name, action, id_fetcher \\ & &1.uuid)

  def broadcast({:error, reason}, _resource_name, _action, _id_fetcher), do: {:error, reason}

  def broadcast(
        {:ok, %{model: resource, version: %PaperTrail.Version{} = version}} = result,
        resource_name,
        :create,
        id_fetcher
      ) do
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, resource_name, {:created, resource, version})

    Phoenix.PubSub.broadcast!(
      Hygeia.PubSub,
      resource_name <> ":" <> id_fetcher.(resource),
      {:updated, resource, version}
    )

    result
  end

  def broadcast(
        {:ok, %{model: resource, version: %PaperTrail.Version{} = version}} = result,
        resource_name,
        :update,
        id_fetcher
      ) do
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, resource_name, {:updated, resource, version})

    Phoenix.PubSub.broadcast!(
      Hygeia.PubSub,
      resource_name <> ":" <> id_fetcher.(resource),
      {:updated, resource, version}
    )

    result
  end

  def broadcast(
        {:ok, %{model: resource, version: %PaperTrail.Version{} = version}} = result,
        resource_name,
        :delete,
        id_fetcher
      ) do
    Phoenix.PubSub.broadcast!(Hygeia.PubSub, resource_name, {:deleted, resource, version})

    Phoenix.PubSub.broadcast!(
      Hygeia.PubSub,
      resource_name <> ":" <> id_fetcher.(resource),
      {:deleted, resource, version}
    )

    result
  end
end
