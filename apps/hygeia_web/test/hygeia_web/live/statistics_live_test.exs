defmodule HygeiaWeb.StatisticsLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:statistics_viewer]]

  describe "ChooseTenant" do
    test "lists all tenants", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      {:ok, _index_live, html} = live(conn, Routes.statistics_choose_tenant_path(conn, :index))

      assert html =~ tenant.name
    end
  end

  describe "Show" do
    test "redirect to dates", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn, Routes.statistics_timeline_path(conn, :show, tenant))

      assert path ==
               Routes.statistics_timeline_path(
                 conn,
                 :show,
                 tenant,
                 Date.utc_today() |> Date.add(-30) |> Date.to_string(),
                 Date.to_string(Date.utc_today())
               )
    end

    test "renders successfully", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      assert {:ok, _live_view, html} =
               live(
                 conn,
                 Routes.statistics_timeline_path(
                   conn,
                   :show,
                   tenant,
                   Date.utc_today() |> Date.add(-30) |> Date.to_string(),
                   Date.to_string(Date.utc_today())
                 )
               )

      assert html =~ tenant.name
    end
  end
end
