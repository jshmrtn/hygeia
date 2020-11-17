defmodule HygeiaWeb.TransmissionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @update_attrs %{
    date: "2020-01-01",
    infection_place: %{
      address: %{
        address: "new address",
        zip: "new zip",
        place: "new place",
        subdivision: "SG",
        country: "CH"
      },
      name: "BrüW",
      known: true,
      activity_mapping_executed: true,
      activity_mapping: "Drank beer, kept distance to other people",
      flight_information: "xyz"
    }
  }
  @invalid_attrs %{date: nil}

  defp create_transmission(_tags) do
    index_case = case_fixture()

    %{
      transmission:
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })
    }
  end

  describe "Show" do
    setup [:create_transmission]

    test "displays transmission", %{conn: conn, transmission: transmission} do
      {:ok, _show_live, html} =
        live(conn, Routes.transmission_show_path(conn, :show, transmission))

      assert html =~ transmission.infection_place.name
    end

    test "updates transmission within modal", %{conn: conn, transmission: transmission} do
      {:ok, show_live, _html} =
        live(conn, Routes.transmission_show_path(conn, :show, transmission))

      assert show_live |> element("a", "Edit") |> render_click()

      assert_patch(show_live, Routes.transmission_show_path(conn, :edit, transmission))

      assert show_live
             |> form("#transmission-form", transmission: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      html =
        show_live
        |> form("#transmission-form", transmission: @update_attrs)
        |> render_submit()

      assert_patch(show_live, Routes.transmission_show_path(conn, :show, transmission))

      assert html =~ "Transmission updated successfully"
      assert html =~ "new address"
    end
  end
end
