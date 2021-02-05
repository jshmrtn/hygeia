defmodule HygeiaIam.ServiceUserToken do
  @moduledoc """
  Keep active Access Token
  """

  use GenServer

  defstruct [:access_token, :user]

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    id =
      case Keyword.fetch(opts, :name) do
        {:ok, {:global, name}} when is_atom(name) -> name
        {:ok, name} when is_atom(name) -> name
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        :error -> Module.concat(__MODULE__, Keyword.fetch!(opts, :user))
      end

    %{super(opts) | id: id}
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:user]),
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        name: Keyword.get(opts, :name, Module.concat(__MODULE__, Keyword.fetch!(opts, :user)))
      )

  @impl GenServer
  def init(opts) do
    user = Keyword.fetch!(opts, :user)
    {:ok, %__MODULE__{access_token: login(user)}}
  end

  @impl GenServer
  def handle_info(:login, %__MODULE__{user: user} = state),
    do: {:noreply, %__MODULE__{state | access_token: login(user)}}

  def handle_info(_other, state), do: {:noreply, state}

  @impl GenServer
  def handle_call(:get_access_token, _from, %__MODULE__{access_token: access_token} = state),
    do: {:reply, access_token, state}

  @spec get_access_token(server :: GenServer.server()) :: String.t()
  def get_access_token(server), do: GenServer.call(server, :get_access_token)

  defp login(user) do
    {:ok, token, expiry} = HygeiaIam.service_login(user)
    Process.send_after(self(), :login, (expiry - 1) * 1000)
    token
  end
end
