defmodule Hygeia.LoginRateLimiter.Worker do
  @moduledoc false

  use GenServer, restart: :transient

  @enforce_keys [:minimal_terminate_timeout, :timeout, :person_uuid]
  defstruct @enforce_keys ++ [:timer, :terminate_timer]

  case Mix.env() do
    :dev ->
      @initial_timeout :timer.seconds(5)
      @timeout_multiplication_factor 2
      @minimal_terminate_timeout :timer.seconds(20)

    _env ->
      @initial_timeout :timer.seconds(1)
      @timeout_multiplication_factor 4
      @minimal_terminate_timeout :timer.minutes(1)
  end

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(__MODULE__, opts,
        name: {:global, {__MODULE__, Keyword.fetch!(opts, :person_uuid)}}
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    person_uuid = Keyword.fetch!(opts, :person_uuid)
    %{super(opts) | id: {__MODULE__, person_uuid}}
  end

  @impl GenServer
  def init(args) do
    {:ok,
     %__MODULE__{
       timeout: Keyword.get(args, :initial_timeout, @initial_timeout),
       person_uuid: Keyword.fetch!(args, :person_uuid),
       minimal_terminate_timeout:
         Keyword.get(args, :minimal_terminate_timeout, @minimal_terminate_timeout)
     }}
  end

  @impl GenServer
  def handle_call(
        {:login, callback},
        _from,
        %__MODULE__{
          timeout: timeout,
          person_uuid: person_uuid,
          timer: nil
        } = state
      ) do
    {success, result} = callback.()

    if success do
      {:reply, {:ok, result}, state}
    else
      case state.terminate_timer do
        nil -> :ok
        timer -> Process.cancel_timer(timer)
      end

      Phoenix.PubSub.broadcast(Hygeia.PubSub, "login_lockout:#{person_uuid}", {:lock, timeout})

      {:reply, {:ok, result},
       %__MODULE__{
         state
         | timeout: timeout * @timeout_multiplication_factor,
           timer: Process.send_after(self(), :unlock, timeout)
       }}
    end
  end

  def handle_call({:login, _callback}, _from, %__MODULE__{timer: _timer} = state),
    do: {:reply, {:error, :locked}, state}

  def handle_call(:locked?, _from, %__MODULE__{timer: nil} = state), do: {:reply, false, state}
  def handle_call(:locked?, _from, %__MODULE__{timer: _timer} = state), do: {:reply, true, state}

  @impl GenServer
  def handle_info(
        :unlock,
        %__MODULE__{
          person_uuid: person_uuid,
          minimal_terminate_timeout: minimal_terminate_timeout,
          timeout: timeout
        } = state
      ) do
    terminate_timeout = max(timeout, minimal_terminate_timeout)

    Phoenix.PubSub.broadcast(Hygeia.PubSub, "login_lockout:#{person_uuid}", :unlock)

    {:noreply,
     %__MODULE__{
       state
       | timer: nil,
         terminate_timer: Process.send_after(self(), :timeout, terminate_timeout)
     }}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end
