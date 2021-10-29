defmodule Hygeia.Helpers.PubSub do
  @moduledoc false

  @spec broadcast(
          result :: {:ok, resource} | {:error, reason},
          resource_name :: String.t(),
          action :: :create | :update | :delete,
          id_fetcher :: (resource -> String.t()),
          additional_topics_fetcher :: (resource -> [String.t()])
        ) :: {:ok, resource} | {:error, reason}
        when resource: term, reason: term
  def broadcast(
        result,
        resource_name,
        action,
        id_fetcher \\ & &1.uuid,
        additional_topics_fetcher \\ fn _reesource -> [] end
      )

  def broadcast(
        {:error, reason},
        _resource_name,
        _action,
        _id_fetcher,
        _additional_topics_fetcher
      ),
      do: {:error, reason}

  for {cause, event} <- %{
        create: :created,
        update: :updated,
        delete: :deleted
      } do
    def broadcast(
          {:ok, resource} = result,
          resource_name,
          unquote(cause),
          id_fetcher,
          additional_topics_fetcher
        ) do
      for topic <- [
            resource_name,
            resource_name <> ":" <> id_fetcher.(resource) | additional_topics_fetcher.(resource)
          ] do
        Phoenix.PubSub.broadcast!(Hygeia.PubSub, topic, {unquote(event), resource, nil})
      end

      result
    end
  end
end
