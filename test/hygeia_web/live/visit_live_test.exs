defmodule HygeiaWeb.VisitLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  # @create_attrs %{
  #   reason: :student,
  #   last_visit_at: Date.add(Date.utc_today(), -5)
  # }
  # @invalid_attrs %{
  #   reason: nil,
  #   last_visit_at: "2021-04-17"
  # }

  defp create_person(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{person: person_fixture(tenant)}
  end

  describe "Index" do
    setup [:create_person]

    test "lists all visits", %{conn: conn, person: person} do
      organisation = organisation_fixture()
      visit = visit_fixture(person, %{reason: :visitor, organisation_uuid: organisation.uuid})

      {:ok, _visit_live, html} = live(conn, Routes.visit_index_path(conn, :index, person))

      assert html =~ "Visits"
      assert html =~ "Visitor"
    end

    test "deletes visit in listing", %{conn: conn, person: person} do
      organisation = organisation_fixture()
      visit = visit_fixture(person, %{reason: :visitor, organisation_uuid: organisation.uuid})

      {:ok, index_live, _html} = live(conn, Routes.visit_index_path(conn, :index, person))

      assert index_live |> element("#visit-#{visit.uuid}") |> render_click()
      refute has_element?(index_live, "#visit-#{visit.uuid}")
    end
  end

  # TODO: Fix test case
  # describe "Create" do
  #   setup [:create_person]

  #   test "saves new visit", %{conn: conn, person: person} do
  #     organisation = organisation_fixture()

  #     {:ok, create_live, _html} = live(conn, Routes.visit_create_path(conn, :create, person.uuid))

  #     assert create_live
  #            |> form("#visit-form", visit: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     {:ok, _, html} =
  #       create_live
  #       |> form("#visit-form", visit: Map.merge(@create_attrs, %{organisation_uuid: organisation.uuid}))
  #       |> render_submit()
  #       |> follow_redirect(conn)

  #     assert html =~ "Visit created successfully"
  #     assert html =~ "test"
  #   end
  # end
end
