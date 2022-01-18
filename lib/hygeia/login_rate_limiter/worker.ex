defmodule Hygeia.LoginRateLimiter.Worker do
  @moduledoc false

  #                              ┌─────── unlock  ─────┐
  #                              │                     │
  #                              ▼                     │
  # ┌──────────┐            ┌──────────┐           ┌───┴────┐            ┌──────────┐
  # │ Start    ├───────────►│ Unlocked │           │ Locked │            │ End      │
  # └──────────┘            └────┬─────┘           └────────┘            └──────────┘
  #                              │                                             ▲
  #                              │                                             │
  #                              └──────────  expire ──────────────────────────┘

  use GenStateMachine

  @enforce_keys [:minimal_terminate_timeout, :timeout, :person_uuid]
  defstruct @enforce_keys

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
      GenStateMachine.start_link(__MODULE__, opts,
        name: {:global, {__MODULE__, Keyword.fetch!(opts, :person_uuid)}}
      )

  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    person_uuid = Keyword.fetch!(opts, :person_uuid)
    Map.merge(super(opts), %{id: {__MODULE__, person_uuid}, restart: :transient})
  end

  @impl GenStateMachine
  # Initial State: unlocked
  # Timeout after @minimal_terminate_timeout
  def init(args) do
    minimal_terminate_timeout =
      Keyword.get(args, :minimal_terminate_timeout, @minimal_terminate_timeout)

    data = %__MODULE__{
      timeout: Keyword.get(args, :initial_timeout, @initial_timeout),
      person_uuid: Keyword.fetch!(args, :person_uuid),
      minimal_terminate_timeout: minimal_terminate_timeout
    }

    {:ok, :unlocked, data,
     [
       {:state_timeout, minimal_terminate_timeout, :expire}
     ]}
  end

  @impl GenStateMachine
  # On successful Login: Shut Down State Machine
  # On failed Login: Switch to locked state and set timeout to `timeout * @timeout_multiplication_factor`
  def handle_event(
        {:call, from},
        {:login, callback},
        :unlocked,
        %__MODULE__{timeout: timeout, person_uuid: person_uuid} = data
      ) do
    {success, result} = callback.()

    if success do
      {:stop_and_reply, :normal,
       [
         {:reply, from, {:ok, result}}
       ], data}
    else
      Phoenix.PubSub.broadcast(Hygeia.PubSub, "login_lockout:#{person_uuid}", {:lock, timeout})

      data = %__MODULE__{data | timeout: timeout * @timeout_multiplication_factor}

      {:next_state, :locked, data,
       [
         {:state_timeout, timeout, :unlock},
         {:reply, from, {:ok, result}}
       ]}
    end
  end

  # On login while locked: Cancel Request
  def handle_event({:call, from}, {:login, _callback}, :locked, _data),
    do:
      {:keep_state_and_data,
       [
         {:reply, from, {:error, :locked}}
       ]}

  # Answer Call if currently locked
  def handle_event({:call, from}, :locked?, :locked, _data),
    do:
      {:keep_state_and_data,
       [
         {:reply, from, true}
       ]}

  def handle_event({:call, from}, :locked?, :unlocked, _data),
    do:
      {:keep_state_and_data,
       [
         {:reply, from, false}
       ]}

  # Unlock State Machine when timeout for lock expired
  def handle_event(
        :state_timeout,
        :unlock,
        :locked,
        %__MODULE__{
          person_uuid: person_uuid,
          minimal_terminate_timeout: minimal_terminate_timeout,
          timeout: timeout
        } = data
      ) do
    Phoenix.PubSub.broadcast(Hygeia.PubSub, "login_lockout:#{person_uuid}", :unlock)

    terminate_timeout = max(timeout, minimal_terminate_timeout)

    {:next_state, :unlocked, data,
     [
       {:state_timeout, terminate_timeout, :expire}
     ]}
  end

  # Shut Down State Machine when unlocked state expires
  def handle_event(:state_timeout, :expire, :unlocked, data), do: {:stop, :normal, data}
end
