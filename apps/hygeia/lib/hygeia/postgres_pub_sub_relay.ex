defmodule Hygeia.PostgresPubSubRelay do
  @moduledoc """
  Relay messages from Postgres LISTEN to PubSub
  """

  use GenServer

  import Hygeia.Helpers.PubSub

  alias Hygeia.Repo

  @enforce_keys [:notification_listener_ref]
  defstruct @enforce_keys

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  @impl GenServer
  def init(_opts) do
    {:ok, ref} = Repo.listen("notification_created")
    {:ok, %__MODULE__{notification_listener_ref: ref}}
  end

  @impl GenServer
  def handle_info(
        {:notification, _pid, ref, "notification_created", payload},
        %__MODULE__{notification_listener_ref: ref} = state
      ) do
    notification =
      Ecto.embedded_load(Hygeia.NotificationContext.Notification, Jason.decode!(payload), :json)

    broadcast(
      {:ok, notification},
      "notifications",
      :create,
      & &1.uuid,
      &["notifications:users:#{&1.user_uuid}"]
    )

    {:noreply, state}
  end
end
