defmodule HygeiaWeb.VisitLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{
    reason: :student,
    last_visit_at: Date.add(Date.utc_today(), -5)
  }
  @invalid_attrs %{
    reason: nil,
    last_visit_at: "2021-04-17"
  }

  defp create_case(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{case_model: case_fixture(person_fixture(tenant))}
  end

  describe "Index" do
    setup [:create_case]

    test "lists all visits", %{conn: conn, case_model: case} do
      organisation = organisation_fixture()
      visit = visit_fixture(case, %{reason: :visitor, organisation_uuid: organisation.uuid})

      {:ok, _visit_live, html} = live(conn, Routes.visit_index_path(conn, :index, case))

      assert html =~ "Visits"
      assert html =~ "Visitor"
      assert html =~ visit.uuid
    end

    test "deletes visit in listing", %{conn: conn, case_model: case} do
      organisation = organisation_fixture()
      visit = visit_fixture(case, %{reason: :visitor, organisation_uuid: organisation.uuid})

      {:ok, index_live, _html} = live(conn, Routes.visit_index_path(conn, :index, case))

      assert index_live |> element("#visit-#{visit.uuid}") |> render_click()
      refute has_element?(index_live, "#visit-#{visit.uuid}")
    end
  end

  describe "Create" do
    setup [:create_case]

    test "saves new visit", %{conn: conn, case_model: case} do
      organisation = organisation_fixture()

      {:ok, create_live, _html} = live(conn, Routes.visit_create_path(conn, :create, case.uuid))

      assert create_live
             |> form("#visit-form", visit: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      render_hook(create_live, :select_visit_organisation, %{"uuid" => organisation.uuid})

      {:ok, _, html} =
        create_live
        |> form("#visit-form",
          visit: Map.merge(@create_attrs, %{organisation_uuid: organisation.uuid})
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Visit created successfully"
      assert html =~ organisation.name
    end
  end

  describe "Update" do
    setup [:create_case]

    test "updates existing visit", %{conn: conn, case_model: case} do
      organisation = organisation_fixture()
      visit = visit_fixture(case)

      {:ok, update_live, _html} = live(conn, Routes.visit_show_path(conn, :edit, visit.uuid))

      assert update_live
             |> form("#visit-form", visit: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      render_hook(update_live, :select_visit_organisation, %{"uuid" => organisation.uuid})

      html =
        update_live
        |> form("#visit-form",
          visit: Map.merge(@create_attrs, %{organisation_uuid: organisation.uuid})
        )
        |> render_submit()

      assert_patched(update_live, Routes.visit_show_path(conn, :show, visit.uuid))

      assert html =~ "Visit updated successfully"
      assert html =~ organisation.name
    end
  end
end
