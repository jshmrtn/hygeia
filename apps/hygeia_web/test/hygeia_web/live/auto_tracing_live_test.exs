defmodule HygeiaWeb.AutoTracingLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaGettext
  import Phoenix.LiveViewTest

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.TenantContext

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp create_case(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    {:ok, tenant} =
      TenantContext.update_tenant(tenant, %{
        iam_domain: "covid19-tracing.ch",
        template_parameters: %{
          sms_signature: "Contact Tracing"
        }
      })

    %{case_model: case_fixture(person_fixture(tenant))}
  end

  defp create_auto_tracing(%{case_model: case}) do
    {:ok, auto_tracing} = AutoTracingContext.create_auto_tracing(case)

    %{auto_tracing: auto_tracing}
  end

  defp set_last_completed_step(auto_tracing, last_completed_step) do
    {:ok, auto_tracing} =
      AutoTracingContext.update_auto_tracing(auto_tracing, %{
        last_completed_step: last_completed_step
      })

    auto_tracing
  end

  describe "Start" do
    setup [:create_case]

    test "starts auto tracing", %{conn: conn, case_model: case} do
      assert_raise HygeiaWeb.AutoTracingLive.AutoTracing.AutoTracingNotFoundError, fn ->
        live(conn, Routes.auto_tracing_auto_tracing_path(conn, :auto_tracing, case))
      end

      create_auto_tracing(%{case_model: case})

      assert {:error, {:live_redirect, %{to: path}}} =
               live(conn, Routes.auto_tracing_auto_tracing_path(conn, :auto_tracing, case))

      assert path == Routes.auto_tracing_start_path(conn, :start, case.uuid)

      {:ok, start_view, html} = live(conn, Routes.auto_tracing_start_path(conn, :start, case))

      assert html =~ gettext("Your Tests")

      assert start_view
             |> element("button", "Collect Data")
             |> render_click()

      assert_redirect(start_view, Routes.auto_tracing_address_path(conn, :address, case))
    end
  end

  describe "Address" do
    setup [:create_case, :create_auto_tracing]

    test "changes address", %{conn: conn, case_model: case, auto_tracing: auto_tracing} do
      set_last_completed_step(auto_tracing, :address)

      {:ok, address_view, _html} =
        live(conn, Routes.auto_tracing_address_path(conn, :address, case))

      assert render_change(address_view, :validate,
               person: %{"address" => %{"address" => "Neugasse 52"}}
             ) =~ "Neugasse 52"
    end

    test "changes isolation address", %{conn: conn, case_model: case, auto_tracing: auto_tracing} do
      set_last_completed_step(auto_tracing, :address)

      {:ok, address_view, _html} =
        live(conn, Routes.auto_tracing_address_path(conn, :address, case))

      assert render_change(address_view, :validate,
               case: %{"monitoring" => %{"address" => %{"address" => "Neugasse 53"}}}
             ) =~ "Neugasse 53"
    end
  end

  describe "Contact Methods" do
    setup [:create_case, :create_auto_tracing]

    test "advances to employer", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :contact_methods)

      {:ok, contact_methods_view, html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      assert html =~ gettext("Please indicate how we can reach you:")

      assert contact_methods_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        contact_methods_view,
        Routes.auto_tracing_employer_path(conn, :employer, case)
      )
    end

    test "change mobile phone with valid data", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :contact_methods)

      {:ok, contact_methods_view, _html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      assert render_change(contact_methods_view, :validate,
               contact_methods: %{"email" => "", "landline" => "", "mobile" => "0789344076"}
             ) =~ "+41 78 934 40 76"
    end

    test "change mobile phone with invalid data returns error", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :contact_methods)

      {:ok, contact_methods_view, _html} =
        live(conn, Routes.auto_tracing_contact_methods_path(conn, :contact_methods, case))

      assert render_change(contact_methods_view, :validate,
               contact_methods: %{
                 "email" => "",
                 "landline" => "",
                 "mobile" => "employement078934407"
               }
             ) =~ "is invalid"
    end
  end

  # TODO: @Antonio, reenable
  # describe "Employer" do
  #   setup [:create_case, :create_auto_tracing]

  #   test "can not advance to vaccination", %{
  #     conn: conn,
  #     case_model: case,
  #     auto_tracing: _auto_tracing
  #   } do
  #     {:ok, employer_view, _html} =
  #       live(conn, Routes.auto_tracing_employer_path(conn, :employer, case))

  #     assert_raise ArgumentError, fn ->
  #       employer_view
  #       |> element("button", "Continue")
  #       |> render_click()
  #     end
  #   end

  #   test "sets employement and advances to vaccination", %{
  #     conn: conn,
  #     case_model: case,
  #     auto_tracing: auto_tracing
  #   } do
  #     {:ok, _auto_tracing} =
  #       AutoTracingContext.update_auto_tracing(auto_tracing, %{"employed" => false})

  #     {:ok, employer_view, _html} =
  #       live(conn, Routes.auto_tracing_employer_path(conn, :employer, case))

  #     assert employer_view
  #            |> element("button", "Continue")
  #            |> render_click()

  #     assert_redirect(
  #       employer_view,
  #       Routes.auto_tracing_vaccination_path(conn, :vaccination, case)
  #     )
  #   end
  # end

  describe "Vaccination" do
    setup [:create_case, :create_auto_tracing]

    test "can not advance to covid_app", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :vaccination)

      {:ok, vaccination_view, html} =
        live(conn, Routes.auto_tracing_vaccination_path(conn, :vaccination, case))

      assert html =~ gettext("Not Done")

      assert_raise ArgumentError, fn ->
        vaccination_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets vaccination and advances to covid_app", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :vaccination)
      case = Repo.preload(case, :person)

      {:ok, _person} =
        CaseContext.update_person(case.person, %{"vaccination" => %{"done" => false}})

      {:ok, vaccination_view, _html} =
        live(conn, Routes.auto_tracing_vaccination_path(conn, :vaccination, case))

      assert vaccination_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        vaccination_view,
        Routes.auto_tracing_covid_app_path(conn, :covid_app, case)
      )
    end
  end

  describe "SwissCovid App" do
    setup [:create_case, :create_auto_tracing]

    test "can not advance to clinical", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :covid_app)

      {:ok, covid_app_view, html} =
        live(conn, Routes.auto_tracing_covid_app_path(conn, :covid_app, case))

      assert html =~ gettext("Is the SwissCovid App installed / in operation on your smartphone?")

      assert_raise ArgumentError, fn ->
        covid_app_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets covid_app and advances to clinical", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      {:ok, auto_tracing} =
        AutoTracingContext.update_auto_tracing(auto_tracing, %{"covid_app" => true})

      set_last_completed_step(auto_tracing, :covid_app)

      {:ok, covid_app_view, _html} =
        live(conn, Routes.auto_tracing_covid_app_path(conn, :covid_app, case))

      assert covid_app_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        covid_app_view,
        Routes.auto_tracing_clinical_path(conn, :clinical, case)
      )
    end
  end

  describe "Clinical" do
    setup [:create_case, :create_auto_tracing]

    test "advances to transmission", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :clinical)

      {:ok, clinical_view, html} =
        live(conn, Routes.auto_tracing_clinical_path(conn, :clinical, case))

      assert html =~ gettext("Do you have or have had symptoms?")

      assert render_change(clinical_view, :validate,
               case: %{
                 "clinical" => %{
                   "has_symptoms" => false
                 }
               }
             )

      assert clinical_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        clinical_view,
        Routes.auto_tracing_transmission_path(conn, :transmission, case)
      )
    end
  end

  describe "Transmission" do
    setup [:create_case, :create_auto_tracing]

    test "can not advance to end", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :transmission)

      {:ok, transmission_view, html} =
        live(conn, Routes.auto_tracing_transmission_path(conn, :transmission, case))

      assert html =~ gettext("Do you know how you got infected?")

      assert_raise ArgumentError, fn ->
        transmission_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets transmission and advances to contact persons", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      {:ok, auto_tracing} =
        AutoTracingContext.update_auto_tracing(auto_tracing, %{
          transmission_known: false
        })

      set_last_completed_step(auto_tracing, :transmission)

      {:ok, transmission_view, _html} =
        live(conn, Routes.auto_tracing_transmission_path(conn, :transmission, case))

      assert transmission_view
             |> form("#auto-tracing-transmission-form")
             |> render_submit()

      assert_redirect(
        transmission_view,
        Routes.auto_tracing_contact_persons_path(conn, :contact_persons, case)
      )
    end
  end
end
