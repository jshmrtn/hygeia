defmodule HygeiaWeb.TransmissionLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @invalid_attrs %{
    type: nil,
    date: nil,
    propagator_internal: nil,
    recipient_internal: nil
  }
  @create_attrs %{
    type: :contact_person,
    date: Date.add(Date.utc_today(), -5),
    propagator_internal: true,
    recipient_internal: true,
    comment: "Drank beer, kept distance to other people",
    infection_place: %{
      address: %{
        address: "new address",
        zip: "new zip",
        place: "new place",
        subdivision: "SG",
        country: "CH"
      },
      name: "BrüW",
      known: true
    }
  }
  @update_attrs %{
    date: Date.add(Date.utc_today(), -7),
    comment: "Drank beer, kept distance to other people",
    infection_place: %{
      address: %{
        address: "new address",
        zip: "new zip",
        place: "new place",
        subdivision: "SG",
        country: "CH"
      },
      name: "BrüW",
      known: true
    }
  }
  @invalid_attrs %{date: nil}

  defp create_transmission(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    index_case = case_fixture(person_fixture(tenant))

    %{
      transmission:
        transmission_fixture(%{
          propagator_internal: true,
          propagator_case_uuid: index_case.uuid
        })
    }
  end

  describe "Create" do
    test "saves new transmission", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      recipient_case = case_fixture(person_fixture(tenant))
      propagator_case = case_fixture(person_fixture(tenant))

      {:ok, create_live, _html} =
        live(
          conn,
          Routes.transmission_create_path(conn, :create,
            type: :contact_person,
            propagator_internal: true,
            recipient_internal: true,
            propagator_case_uuid: propagator_case.uuid,
            recipient_case_uuid: recipient_case.uuid
          )
        )

      assert create_live
             |> form("#transmission-form", transmission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_live
      |> form("#transmission-form",
        transmission: %{type: :contact_person, infection_place: %{known: true}}
      )
      |> render_change()

      create_live
      |> form("#transmission-form",
        transmission: %{type: :contact_person, infection_place: %{known: true}}
      )
      |> render_change()

      {:ok, _view, html} =
        create_live
        |> form("#transmission-form",
          transmission: @create_attrs
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "BrüW"
    end

    test "saves new flight transmission", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      recipient_case = case_fixture(person_fixture(tenant))

      {:ok, create_live, _html} =
        live(
          conn,
          Routes.transmission_create_path(conn, :create,
            type: :travel,
            recipient_internal: true,
            recipient_case_uuid: recipient_case.uuid
          )
        )

      assert create_live
             |> form("#transmission-form", transmission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_live
      |> form("#transmission-form",
        transmission: %{type: :travel, infection_place: %{known: true}}
      )
      |> render_change()

      create_live
      |> form("#transmission-form",
        transmission: %{type: :travel, infection_place: %{type: :flight}}
      )
      |> render_change()

      {:ok, _view, html} =
        create_live
        |> form("#transmission-form",
          transmission:
            Map.update(
              Map.drop(@create_attrs, [:propagator_internal]),
              :infection_place,
              %{},
              &Map.put(&1, :flight_information, "flight xyz")
            )
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "BrüW"
      assert html =~ "flight xyz"
    end
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
             |> render_change() =~ "can&#39;t be blank"

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
