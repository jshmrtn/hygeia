defmodule HygeiaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use HygeiaWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import HygeiaWeb.ConnCase

      alias HygeiaWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint HygeiaWeb.Endpoint
    end
  end

  setup tags do
    conn = build_conn()

    case tags[:log_in] do
      nil ->
        {:ok, conn: conn}

      true ->
        user = Hygeia.Fixtures.user_fixture(%{iam_sub: Ecto.UUID.generate()})

        {:ok, conn: init_test_session(conn, auth: user), user: user}

      params ->
        user = Hygeia.Fixtures.user_fixture(Enum.into(params, %{iam_sub: Ecto.UUID.generate()}))

        {:ok, conn: init_test_session(conn, auth: user), user: user}
    end
  end
end
