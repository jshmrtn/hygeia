defmodule HygeiaWeb.RiskCountryLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.RiskCountryContext

  alias HygeiaWeb.Helpers.Region

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp add_risk_country(_tags) do
    %{risk_country: risk_country_fixture()}
  end

  describe "Index" do
    setup [:add_risk_country]

    test "lists all risk countries", %{conn: conn, risk_country: risk_country} do
      {:ok, _index_live, html} = live(conn, Routes.risk_country_index_path(conn, :index))

      assert html =~ "Listing high risk countries"
      assert html =~ Region.country_name(risk_country.country)
    end
  end

  describe "Edit" do
    setup [:add_risk_country]

    test "navigates to edit view", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.risk_country_index_path(conn, :index))

      assert index_live
             |> element("#edit_list")
             |> render_click()
             |> follow_redirect(conn)

      assert_redirect(
        index_live,
        Routes.risk_country_index_path(conn, :edit)
      )
    end

    test "adds new risk country to the list", %{conn: conn, risk_country: risk_country} do
      {:ok, index_live, html} = live(conn, Routes.risk_country_index_path(conn, :edit))

      assert index_live
             |> form("#risk-countries-form",
               index: %{
                 countries: %{
                   0 => %{country: "AF", is_risk_country: true}
                 }
               }
             )
             |> render_submit()

      assert_redirect(index_live, Routes.risk_country_index_path(conn, :index))

      assert html =~ "Listing high risk countries"
      assert html =~ Region.country_name("AF")
      assert html =~ Region.country_name(risk_country.country)
    end

    test "remove risk country from the list - remove country button", %{
      conn: conn,
      risk_country: risk_country
    } do
      {:ok, index_live, html} = live(conn, Routes.risk_country_index_path(conn, :edit))

      assert html =~ Region.country_name(risk_country.country)

      assert index_live
             |> element("#remove_country-CH")
             |> render_click()

      assert index_live
             |> form("#risk-countries-form")
             |> render_submit()

      assert_redirect(index_live, Routes.risk_country_index_path(conn, :index))

      assert [] = RiskCountryContext.list_risk_countries()
    end
  end
end
