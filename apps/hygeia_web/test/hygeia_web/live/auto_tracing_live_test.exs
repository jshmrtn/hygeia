defmodule HygeiaWeb.AutoTracingLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaGettext
  import Phoenix.LiveViewTest

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp create_case(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{case_model: case_fixture(person_fixture(tenant))}
  end

  defp create_auto_tracing(%{case_model: case}) do
    {:ok, auto_tracing} = AutoTracingContext.create_auto_tracing(case)

    %{auto_tracing: auto_tracing}
  end

  defp update_auto_tracing(auto_tracing, current_step, last_completed_step) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(auto_tracing, %{
        current_step: current_step,
        last_completed_step: last_completed_step
      })

    auto_tracing
  end

  describe "Start" do
    setup [:create_case]

    test "starts auto tracing", %{conn: conn, case_model: case} do
      case = Repo.preload(case, person: [])

      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn, Routes.auto_tracing_auto_tracing_path(conn, :auto_tracing, case))

      assert path == Routes.auto_tracing_start_path(conn, :start, case.uuid)

      {:ok, start_view, html} = live(conn, Routes.auto_tracing_start_path(conn, :start, case))

      assert html =~ gettext("Your Tests")

      {:ok, _, html} =
        start_view
        |> render_submit(:advance, %{})
        |> follow_redirect(conn)

      assert html =~ gettext("Address / Isolation Address")
      assert html =~ "Neugasse 51"
    end
  end

  describe "Address" do
    setup [:create_case, :create_auto_tracing]

    test "advances to contact methods", %{
      conn: conn,
      case_model: case,
      auto_tracing: _auto_tracing
    } do
      {:ok, address_view, _html} =
        live(conn, Routes.auto_tracing_address_path(conn, :address, case))

      {:ok, _, html} =
        address_view
        |> render_submit(:advance, %{})
        |> follow_redirect(conn)

      assert html =~ gettext("How can we contact you?")
    end

    test "changes address", %{conn: conn, case_model: case, auto_tracing: _auto_tracing} do
      {:ok, address_view, _html} =
        live(conn, Routes.auto_tracing_address_path(conn, :address, case))

      assert render_change(address_view, :validate,
               person: %{"address" => %{"address" => "Neugasse 52"}}
             ) =~ "Neugasse 52"
    end

    test "changes isolation address", %{conn: conn, case_model: case, auto_tracing: _auto_tracing} do
      {:ok, address_view, _html} =
        live(conn, Routes.auto_tracing_address_path(conn, :address, case))

      assert render_change(address_view, :validate,
               case: %{"monitoring" => %{"address" => %{"address" => "Neugasse 53"}}}
             ) =~ "Neugasse 53"
    end

    # test "changes tenant through person address", %{
    #   conn: conn,
    #   case_model: case,
    #   auto_tracing: auto_tracing
    # } do
    #   {:ok, address_view, _html} =
    #     live(conn, Routes.auto_tracing_address_path(conn, :address, case))

    #   assert render_change(address_view, :validate,
    #            person: %{"address" => %{"subdivision" => "ZH"}}+41 78 934 40 76
    #          ) =~ "ZH"
    # end

    # test "does not change tenant through person address", %{
    #   conn: conn,
    #   case_model: case,
    #   auto_tracing: auto_tracing
    # } do
    # end

    # test "changes tenant through isolation address", %{
    #   conn: conn,
    #   case_model: case,
    #   auto_tracing: auto_tracing
    # } do
    # end
  end

  describe "Contact Methods" do
    setup [:create_case, :create_auto_tracing]

    test "advances to employer", %{
      conn: conn,
      case_model: case,
      auto_tracing: _auto_tracing
    } do
      {:ok, contact_methods_view, _html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      {:ok, _, html} =
        contact_methods_view
        |> render_submit(:advance, %{})
        |> follow_redirect(conn)

      assert html =~ "Occupation / Employment"
    end

    test "change mobile phone with valid data", %{
      conn: conn,
      case_model: case,
      auto_tracing: _auto_tracing
    } do
      {:ok, contact_methods_view, _html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      assert render_change(contact_methods_view, :validate,
               auto_tracing: %{"email" => "", "landline" => "", "mobile" => "0789344076"}
             ) =~ "+41 78 934 40 76"
    end

    test "change mobile phone with invalid data returns error", %{
      conn: conn,
      case_model: case,
      auto_tracing: _auto_tracing
    } do
      {:ok, contact_methods_view, _html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      assert render_change(contact_methods_view, :validate,
               auto_tracing: %{"email" => "", "landline" => "", "mobile" => "078934407"}
             ) =~ "is invalid"
    end
  end
end
