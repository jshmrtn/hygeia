defmodule Hygeia.LoginRateLimiterTest do
  @moduledoc false
  use ExUnit.Case

  alias Hygeia.LoginRateLimiter

  doctest LoginRateLimiter

  describe "handle_login/3" do
    test "waits until time elapses" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      assert {:ok, "hello"} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
                 initial_timeout: 10
               )

      assert_received {:lock, 10}

      refute_receive :unlock, 9
      assert_receive :unlock, 2
    end

    test "increases timeout on multiple failures by factor 4" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      assert {:ok, "hello"} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
                 initial_timeout: 10
               )

      assert_receive :unlock, 11

      assert {:ok, "hello"} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
                 initial_timeout: 10
               )

      refute_receive :unlock, 39
      assert_receive :unlock, 2
    end

    test "can't do multiple logins at the same time" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      assert {:ok, "hello"} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
                 initial_timeout: 10
               )

      assert {:error, :locked} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
                 initial_timeout: 10
               )
    end

    test "login success does not block" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      assert {:ok, "hello"} =
               LoginRateLimiter.handle_login(person_uuid, fn -> {true, "hello"} end,
                 initial_timeout: 10
               )

      refute_received {:lock, _time}
    end
  end

  describe "auto termination" do
    test "terminates after timeout elapsed twice" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
        initial_timeout: 10,
        minimal_terminate_timeout: 1
      )

      pid = GenServer.whereis({:global, {LoginRateLimiter.Worker, person_uuid}})

      Process.monitor(pid)

      assert_receive :unlock, 11

      refute LoginRateLimiter.locked?(person_uuid)

      refute_receive {:DOWN, _ref, :process, ^pid, :normal}, 39
      assert_receive {:DOWN, _ref, :process, ^pid, :normal}, 2
    end

    test "does not terminate early" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
        initial_timeout: 10,
        minimal_terminate_timeout: 1
      )

      assert_receive :unlock, 11

      LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
        initial_timeout: 10,
        minimal_terminate_timeout: 1
      )

      assert_receive :unlock, 41
    end

    test "terminates no earlier than minimal teminate timeout" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end,
        initial_timeout: 1,
        minimal_terminate_timeout: 10
      )

      pid = GenServer.whereis({:global, {LoginRateLimiter.Worker, person_uuid}})

      Process.monitor(pid)

      assert_receive :unlock, 2
      refute_receive {:DOWN, _ref, :process, ^pid, :normal}, 9
      assert_receive {:DOWN, _ref, :process, ^pid, :normal}, 2
    end
  end

  describe "locked?/2" do
    test "yields correct result" do
      person_uuid = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Hygeia.PubSub, "login_lockout:#{person_uuid}")

      refute LoginRateLimiter.locked?(person_uuid)

      LoginRateLimiter.handle_login(person_uuid, fn -> {false, "hello"} end, initial_timeout: 10)

      assert LoginRateLimiter.locked?(person_uuid)

      assert_receive :unlock

      refute LoginRateLimiter.locked?(person_uuid)
    end
  end
end
