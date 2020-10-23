defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaWeb.Helpers.Case
  import Phoenix.LiveViewTest

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: true

  @create_attrs %{
    complexity: :medium,
    status: :first_contact,
    phases: %{
      "0" => %{
        type: :possible_index,
        start: Date.utc_today()
      }
    }
  }
  @update_attrs %{
    complexity: :high,
    status: :done
  }

  # @invalid_attrs %{
  #   complexity: "",
  #   status: "",
  # }

  defp create_case(_tags) do
    %{case_model: case_fixture()}
  end

  describe "Index" do
    setup [:create_case]

    test "lists all cases", %{conn: conn, case_model: case} do
      {:ok, _index_live, html} = live(conn, Routes.case_index_path(conn, :index))

      assert html =~ "Listing Cases"
      assert html =~ case_complexity_translation(case.complexity)
    end

    test "saves new case", %{conn: conn} do
      tenant = tenant_fixture()
      user = user_fixture()
      person = person_fixture(tenant)

      {:ok, index_live, _html} = live(conn, Routes.case_index_path(conn, :index))

      assert index_live |> element("a", "New Case") |> render_click() =~
               "New Case"

      assert_patch(index_live, Routes.case_index_path(conn, :new))

      # assert index_live
      #        |> form("#case-form", case: @invalid_attrs)
      #        |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#case-form",
          case:
            Map.merge(@create_attrs, %{
              tenant_uuid: tenant.uuid,
              tracer_uuid: user.uuid,
              supervisor_uuid: user.uuid,
              person_uuid: person.uuid
            })
        )
        |> render_submit()
        |> follow_redirect(conn, Routes.case_index_path(conn, :index))

      assert html =~ "Case created successfully"
      assert html =~ case_complexity_translation(@create_attrs.complexity)
    end

    # test "updates case in listing", %{conn: conn, case_model: case} do
    #   {:ok, index_live, _html} = live(conn, Routes.case_index_path(conn, :index))

    #   assert index_live |> element("#case-#{case.uuid} a", "Edit") |> render_click() =~
    #            "Edit Case"

    #   assert_patch(index_live, Routes.case_index_path(conn, :edit, case))

    #   # assert index_live
    #   #        |> form("#case-form", case: @invalid_attrs)
    #   #        |> render_change() =~ "can&apos;t be blank"

    #   {:ok, _, html} =
    #     index_live
    #     |> form("#case-form", case: @update_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.case_index_path(conn, :index))

    #   assert html =~ "Case updated successfully"
    #   assert html =~ Atom.to_string(@update_attrs.complexity)
    # end

    test "deletes case in listing", %{conn: conn, case_model: case} do
      {:ok, index_live, _html} = live(conn, Routes.case_index_path(conn, :index))

      assert index_live |> element("#case-#{case.uuid} a[title=Delete]") |> render_click()
      refute has_element?(index_live, "#case-#{case.uuid}")
    end
  end

  describe "Show" do
    setup [:create_case]

    test "displays case", %{conn: conn, case_model: case} do
      {:ok, _show_live, html} = live(conn, Routes.case_show_path(conn, :show, case))

      assert html =~ "Show Case"
      assert html =~ Atom.to_string(case.complexity)
    end

    # test "updates case within modal", %{conn: conn, case_model: case} do
    #   {:ok, show_live, _html} = live(conn, Routes.case_show_path(conn, :show, case))

    #   assert show_live |> element("a", "Edit") |> render_click() =~
    #            "Edit Case"

    #   assert_patch(show_live, Routes.case_show_path(conn, :edit, case))

    #   # assert show_live
    #   #        |> form("#case-form", case: @invalid_attrs)
    #   #        |> render_change() =~ "can&apos;t be blank"

    #   {:ok, _, html} =
    #     show_live
    #     |> form("#case-form", case: @update_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.case_show_path(conn, :show, case))

    #   assert html =~ "Case updated successfully"
    #   assert html =~ Atom.to_string(@update_attrs.complexity)
    # end
  end
end
