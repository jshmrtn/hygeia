defmodule Hygeia.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Hygeia.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox

  alias Hygeia.Helpers.Versioning

  using do
    quote location: :keep do
      alias Hygeia.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Hygeia.DataCase
      import Hygeia.Fixtures
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Hygeia.Repo)

    unless tags[:async] do
      Sandbox.mode(Hygeia.Repo, {:shared, self()})
    end

    case tags[:origin] do
      nil -> nil
      origin -> Versioning.put_origin(origin)
    end

    case tags[:originator] do
      nil -> nil
      originator -> Versioning.put_originator(originator)
    end

    Phoenix.PubSub.subscribe(Hygeia.PubSub, "system_message_cache")
    start_supervised!(Hygeia.SystemMessageContext.SystemMessageCache)
    assert_receive :refresh
    Phoenix.PubSub.unsubscribe(Hygeia.PubSub, "system_message_cache")

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  @spec errors_on(changeset :: Ecto.Changeset.t(resource)) :: [String.t()] when resource: term
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _message, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @spec execute_materialized_view_refresh(view :: atom) :: :ok
  def execute_materialized_view_refresh(view) do
    SQL.query!(Hygeia.Repo, "REFRESH MATERIALIZED VIEW #{view}")

    :ok
  end
end
