defmodule HygeiaWeb.AutoTracingLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaGettext
  import Phoenix.LiveViewTest

  alias Hygeia.AutoTracingContext
  alias Hygeia.AutoTracingContext.AutoTracing
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.TenantContext

  alias HygeiaWeb.Helpers.Region

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

    %{
      case_model:
        case_fixture(
          person_fixture(tenant),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          user_fixture(%{iam_sub: Ecto.UUID.generate()}),
          %{clinical: nil}
        )
    }
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
               case: %{
                 "monitoring" => %{
                   "location" => "hotel",
                   "location_details" => "Hotel Mama",
                   "different_location" => "true",
                   "address" => %{
                     "address" => "Neugasse 53",
                     "country" => "CH",
                     "place" => "St. Gallen",
                     "subdivision" => "SG",
                     "zip" => "8405"
                   }
                 }
               }
             ) =~ "Neugasse 53"
    end
  end

  describe "Contact Methods" do
    setup [:create_case, :create_auto_tracing]

    test "advances to visits", %{
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
        Routes.auto_tracing_visits_path(conn, :visits, case)
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

  describe "Visits" do
    setup [:create_case, :create_auto_tracing]

    test "cannot advance to employer", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :visits)

      {:ok, visits_view, _html} = live(conn, Routes.auto_tracing_visits_path(conn, :visits, case))

      assert_raise ArgumentError, fn ->
        visits_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets school visit and and advances to employer", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :visits)

      {:ok, visits_view, _html} = live(conn, Routes.auto_tracing_visits_path(conn, :visits, case))

      assert visits_view
             |> form("#visits-form", visits: %{has_visited: true})
             |> render_change() =~
               "please add at least one educational institution that you visited during the period in consideration"

      assert visits_view
             |> form("#visits-form")
             |> render_change(
               visits: %{
                 organisation_visits: %{
                   "0" => %{
                     visit_reason: :professor,
                     visited_at: "2021-04-17",
                     not_found: true
                   }
                 }
               }
             )

      assert visits_view
             |> form("#visits-form")
             |> render_change(
               visits: %{
                 organisation_visits: %{
                   0 => %{
                     is_occupied: false,
                     unknown_organisation: %{
                       name: "test_school",
                       address: %{address: "teststrasse 10", country: "CH", subdivision: "ZH"}
                     }
                   }
                 }
               }
             )

      assert visits_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        visits_view,
        Routes.auto_tracing_employer_path(conn, :employer, case)
      )

      assert %AutoTracing{
               scholar: true,
               unsolved_problems: [:school_related]
             } = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)

      assert %Person{
               affiliations: []
             } =
               case.person_uuid
               |> CaseContext.get_person!()
               |> Repo.preload(:affiliations)

      assert %Case{visits: [_]} = case.uuid |> CaseContext.get_case!() |> Repo.preload(:visits)
    end

    test "sets school visit with employment and advances to employer", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :visits)

      {:ok, visits_view, _html} = live(conn, Routes.auto_tracing_visits_path(conn, :visits, case))

      assert visits_view
             |> form("#visits-form", visits: %{has_visited: true})
             |> render_change() =~
               "please add at least one educational institution that you visited during the period in consideration"

      assert visits_view
             |> form("#visits-form")
             |> render_change(
               visits: %{
                 organisation_visits: %{
                   "0" => %{
                     visit_reason: :professor,
                     visited_at: "2021-04-17",
                     not_found: true
                   }
                 }
               }
             )

      assert visits_view
             |> form("#visits-form")
             |> render_change(
               visits: %{
                 organisation_visits: %{
                   0 => %{
                     is_occupied: true,
                     unknown_organisation: %{
                       name: "test_school",
                       address: %{address: "teststrasse 10", country: "CH", subdivision: "ZH"}
                     }
                   }
                 }
               }
             )

      assert visits_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        visits_view,
        Routes.auto_tracing_employer_path(conn, :employer, case)
      )

      assert %AutoTracing{
               scholar: true,
               unsolved_problems: unsolved_problems
             } = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)

      expected_unsolved_problems = [:school_related]

      assert Enum.sort(unsolved_problems) == Enum.sort(expected_unsolved_problems)

      assert %Person{
               affiliations: [_]
             } =
               case.person_uuid
               |> CaseContext.get_person!()
               |> Repo.preload(:affiliations)

      assert %Case{visits: [_]} = case.uuid |> CaseContext.get_case!() |> Repo.preload(:visits)
    end
  end

  describe "Employer" do
    setup [:create_case, :create_auto_tracing]

    test "cannot advance to vaccination", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :employer)

      {:ok, employer_view, _html} =
        live(conn, Routes.auto_tracing_employer_path(conn, :employer, case))

      assert_raise ArgumentError, fn ->
        employer_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets no occupation and advances to vaccination", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :employer)

      {:ok, employer_view, _html} =
        live(conn, Routes.auto_tracing_employer_path(conn, :employer, case))

      assert employer_view
             |> form("#employer-form", employer: %{employed: false})
             |> render_change()

      assert employer_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        employer_view,
        Routes.auto_tracing_vaccination_path(conn, :vaccination, case)
      )

      assert %AutoTracing{
               employed: false
             } = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end

    test "sets one occupation and advances to vaccination", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :employer)

      {:ok, employer_view, _html} =
        live(conn, Routes.auto_tracing_employer_path(conn, :employer, case))

      assert employer_view
             |> form("#employer-form", employer: %{employed: true})
             |> render_change() =~
               "please add at least one occupation"

      assert employer_view
             |> form("#employer-form")
             |> render_change(
               employer: %{
                 occupations: %{
                   "0" => %{
                     kind: :employee,
                     not_found: true
                   }
                 }
               }
             )

      assert employer_view
             |> form("#employer-form")
             |> render_change(
               employer: %{
                 occupations: %{
                   0 => %{
                     unknown_organisation: %{
                       name: "test_organisation",
                       address: %{address: "teststrasse 10", country: "CH", subdivision: "ZH"}
                     }
                   }
                 }
               }
             )

      assert employer_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        employer_view,
        Routes.auto_tracing_vaccination_path(conn, :vaccination, case)
      )

      assert %AutoTracing{employed: true, unsolved_problems: [:new_employer]} =
               AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end
  end

  describe "Vaccination" do
    setup [:create_case, :create_auto_tracing]

    test "cannot advance to covid_app", %{
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

    test "cannot advance to clinical", %{
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

    test "advances to travel", %{
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
        Routes.auto_tracing_travel_path(conn, :travel, case)
      )
    end

    test "symptoms far back and recent positive test, advances to travel", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      test_date = Date.add(Date.utc_today(), -20)

      test_fixture(case, %{tested_at: test_date, laboratory_reported_at: test_date})

      set_last_completed_step(auto_tracing, :clinical)

      {:ok, clinical_view, html} =
        live(conn, Routes.auto_tracing_clinical_path(conn, :clinical, case))

      assert html =~ gettext("Do you have or have had symptoms?")

      assert clinical_view
             |> form("#autotracing-clinical-form",
               case: %{
                 "clinical" => %{
                   "has_symptoms" => true
                 }
               }
             )
             |> render_change(
               case: %{
                 "clinical" => %{
                   "symptoms" => [
                     :fever,
                     :cough
                   ],
                   "symptom_start" => Date.add(Date.utc_today(), -70)
                 }
               }
             ) =~ gettext("Are you sure? This date is unusual far in the past.")

      assert clinical_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        clinical_view,
        Routes.auto_tracing_travel_path(conn, :travel, case)
      )

      phases =
        case.uuid
        |> CaseContext.get_case!()
        |> Map.get(:phases)

      assert %Case.Phase{details: %Case.Phase.Index{}, quarantine_order: false} =
               Enum.find(
                 phases,
                 &match?(%Case.Phase{details: %Case.Phase.Index{}}, &1)
               )

      assert %AutoTracing{
               unsolved_problems: [:phase_ends_in_the_past]
             } = auto_tracing = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)

      assert AutoTracing.has_problem?(auto_tracing, :phase_ends_in_the_past)
    end
  end

  describe "Travel" do
    setup [:create_case, :create_auto_tracing]

    test "cannot advance to transmission", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :travel)

      {:ok, travel_view, _html} = live(conn, Routes.auto_tracing_travel_path(conn, :travel, case))

      assert_raise ArgumentError, fn ->
        travel_view
        |> element("button", "Continue")
        |> render_click()
      end
    end

    test "sets no flight and advances to transmission", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :travel)

      {:ok, travel_view, _html} = live(conn, Routes.auto_tracing_travel_path(conn, :travel, case))

      assert travel_view
             |> form("#travel-form", travel: %{has_flown: false})
             |> render_change()

      assert travel_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        travel_view,
        Routes.auto_tracing_transmission_path(conn, :transmission, case)
      )

      assert %AutoTracing{has_flown: false, flights: [], travels: []} =
               AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end

    test "sets no flight and cannot advance to transmission when there is a risk country", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      risk_country = risk_country_fixture()

      set_last_completed_step(auto_tracing, :travel)

      {:ok, travel_view, html} = live(conn, Routes.auto_tracing_travel_path(conn, :travel, case))

      assert html =~ Region.country_name(risk_country.country)

      assert travel_view
             |> form("#travel-form", travel: %{has_flown: false})
             |> render_change()

      assert_raise ArgumentError, fn ->
        travel_view
        |> element("button", "Continue")
        |> render_click()
      end

      assert %AutoTracing{has_flown: nil, flights: [], travels: []} =
               AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end

    test "sets no risk travel, no flight and advances to transmission", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      risk_country = risk_country_fixture()

      set_last_completed_step(auto_tracing, :travel)

      {:ok, travel_view, html} = live(conn, Routes.auto_tracing_travel_path(conn, :travel, case))

      assert html =~ Region.country_name(risk_country.country)

      assert travel_view
             |> form("#travel-form",
               travel: %{has_not_travelled_in_risk_country: true, has_flown: false}
             )
             |> render_change()

      assert travel_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        travel_view,
        Routes.auto_tracing_transmission_path(conn, :transmission, case)
      )

      assert %AutoTracing{has_flown: false, flights: [], travels: []} =
               AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)
    end

    test "sets one risk tavel and related flight and advances to transmission", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      risk_country_fixture()

      set_last_completed_step(auto_tracing, :travel)

      {:ok, travel_view, html} = live(conn, Routes.auto_tracing_travel_path(conn, :travel, case))

      assert travel_view
             |> form("#travel-form",
               travel: %{has_not_travelled_in_risk_country: false, has_flown: true}
             )
             |> render_change() =~
               "please add at least one flight that you took during the period in consideration"

      assert html =~ "is required"

      assert travel_view
             |> form("#travel-form")
             |> render_change(
               travel: %{
                 risk_countries_travelled: %{
                   0 => %{
                     is_selected: true,
                     travel: %{
                       country: "CH",
                       last_departure_date: "2021-04-17"
                     }
                   }
                 },
                 flights: %{
                   "0" => %{
                     flight_date: "2021-04-17",
                     departure_place: "Zürich",
                     arrival_place: "Rome",
                     flight_number: "FNDORL",
                     seat_number: "B-23",
                     wore_mask: false
                   }
                 }
               }
             )

      assert travel_view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(
        travel_view,
        Routes.auto_tracing_transmission_path(conn, :transmission, case)
      )

      assert %AutoTracing{
               has_flown: true,
               flights: [_],
               travels: [_],
               unsolved_problems: [_, _]
             } = auto_tracing = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)

      assert AutoTracing.has_problem?(auto_tracing, :high_risk_country_travel)
      assert AutoTracing.has_problem?(auto_tracing, :flight_related)
    end
  end

  describe "Transmission" do
    setup [:create_case, :create_auto_tracing]

    test "cannot advance to end", %{
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

  describe "End" do
    setup [:create_case, :create_auto_tracing]

    test "loads", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      set_last_completed_step(auto_tracing, :contact_persons)

      {:ok, _transmission_view, html} = live(conn, Routes.auto_tracing_end_path(conn, :end, case))

      assert html =~ "Thank you for your information!"
    end

    test "removes exisitng no_reaction problem", %{
      conn: conn,
      case_model: case,
      auto_tracing: auto_tracing
    } do
      {:ok, auto_tracing} =
        AutoTracingContext.auto_tracing_add_problem(auto_tracing, :no_reaction)

      set_last_completed_step(auto_tracing, :contact_persons)

      {:ok, _transmission_view, _html} =
        live(conn, Routes.auto_tracing_end_path(conn, :end, case))

      auto_tracing = AutoTracingContext.get_auto_tracing!(auto_tracing.uuid)

      refute AutoTracingContext.AutoTracing.has_problem?(auto_tracing, :no_reaction)
    end
  end
end
