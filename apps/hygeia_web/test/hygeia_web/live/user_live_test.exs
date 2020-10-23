defmodule HygeiaWeb.UserLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  defp create_user(_tags) do
    %{user: user_fixture()}
  end

  describe "Index" do
    setup [:create_user]

    test "lists all user", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, Routes.user_index_path(conn, :index))

      assert html =~ "Listing User"
      assert html =~ user.display_name
    end
  end

  describe "Show" do
    setup [:create_user]

    test "displays user", %{conn: conn, user: user} do
      {:ok, _show_live, html} = live(conn, Routes.user_show_path(conn, :show, user))

      assert html =~ "Show User"
      assert html =~ user.display_name
    end
  end
end
