# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest
  import HygeiaWeb.CaseLiveTestHelper

  alias Hygeia.AutoTracingContext
  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CaseContext.Transmission
  alias Hygeia.OrganisationContext.Affiliation

  alias HygeiaWeb.CaseLive.CreatePossibleIndex.Service

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  defp create_case(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{case_model: case_fixture(person_fixture(tenant))}
  end

  describe "Index" do
    setup [:create_case]

    test "lists all cases", %{conn: conn, case_model: case} do
      {:ok, _index_live, html} =
        live(
          conn,
          Routes.case_index_path(conn, :index,
            filter: %{does_not: "matter"},
            sort: ["asc_inserted_at"]
          )
        )

      assert html =~ "Listing Cases"
      assert html =~ Case.Complexity.translate(case.complexity)
    end

    test "filters no auto tracing problems", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      problem_case = case_fixture(person_fixture(tenant))
      {:ok, problem_auto_tracing} = AutoTracingContext.create_auto_tracing(problem_case)

      {:ok, _problem_auto_tracing} =
        AutoTracingContext.auto_tracing_add_problem(problem_auto_tracing, :no_reaction)

      no_problem_case = case_fixture(person_fixture(tenant))
      {:ok, _no_problem_auto_tracing} = AutoTracingContext.create_auto_tracing(no_problem_case)

      {:ok, _index_live, html} =
        live(
          conn,
          Routes.case_index_path(conn, :index,
            filter: %{no_auto_tracing_problems: "true"},
            sort: ["asc_inserted_at"]
          )
        )

      assert html =~ no_problem_case.uuid
      refute html =~ problem_case.uuid
    end

    test "filters complete auto tracing", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      complete_case = case_fixture(person_fixture(tenant))

      {:ok, _complete_auto_tracing} =
        AutoTracingContext.create_auto_tracing(complete_case, %{
          current_step: :end,
          last_completed_step: :end
        })

      incomplete_case = case_fixture(person_fixture(tenant))
      {:ok, _incomplete_auto_tracing} = AutoTracingContext.create_auto_tracing(incomplete_case)

      {:ok, _index_live, html} =
        live(
          conn,
          Routes.case_index_path(conn, :index,
            filter: %{auto_tracing_active: "complete"},
            sort: ["asc_inserted_at"]
          )
        )

      assert html =~ complete_case.uuid
      refute html =~ incomplete_case.uuid
    end
  end

  describe "Show" do
    setup [:create_case]

    test "displays case", %{conn: conn, case_model: case} do
      {:ok, _show_live, html} = live(conn, Routes.case_base_data_path(conn, :show, case))

      assert html =~ Atom.to_string(case.complexity)
    end
  end

  describe "Create" do
    @valid_attrs %{"phases" => %{0 => %{"type" => "index"}}}
    @invalid_attrs %{"phases" => %{0 => %{"type" => nil}}}

    test "saves new case", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      person = person_fixture(tenant)

      {:ok, create_live, _html} = live(conn, Routes.case_create_path(conn, :create))

      assert create_live
             |> form("#case-form",
               case: Map.merge(%{"tenant_uuid" => tenant.uuid}, @invalid_attrs)
             )
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        create_live
        |> form("#case-form", case: Map.merge(%{"tenant_uuid" => tenant.uuid}, @valid_attrs))
        |> render_submit(%{
          "case" => %{
            "person_uuid" => person.uuid,
            "phases" => %{0 => %{"details" => %{"__type__" => "index"}}}
          }
        })
        |> follow_redirect(conn)

      assert html =~ "Case created successfully"
      assert html =~ "some first_name"
    end
  end

  describe "CreatePossibleIndex - Path navigation" do
    test "navigate to step without reaching it", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: _}}} =
               live(
                 conn,
                 Routes.case_create_possible_index_path(conn, :index, "action")
               )
    end
  end

  # TODO: Fix problems with contact methods

  describe "CreatePossibleIndex" do
    test "type: travel, new person, new case, status: first_contact",
         %{conn: conn, user: user} = context do
      type = :travel
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"
      # mobile = "+41 78 724 57 90"
      # email = "karl.muster@gmail.com"

      case_status = :first_contact

      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      [%{tenant: tenant} | _other_grants] = user.grants

      view
      |> test_transmission_step(context, %{
        type: type,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name,
        # contact_methods: [
        #   %{type: :mobile, value: mobile},
        #   %{type: :email, value: email}
        # ],
        tenant_uuid: tenant.uuid,
        address: %{
          address: "Teststrasse 2"
        }
      })
      |> test_define_people_step_submit_person_modal(context, %{})
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => "0",
        "case" => %{status: case_status}
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name,
                 last_name: ^last_name
                 #  contact_methods: [
                 #    %{type: :mobile, value: ^mobile},
                 #    %{type: :email, value: ^email}
                 #  ]
               }
             ] = CaseContext.list_people()

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: ^type},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid
               }
             ] = CaseContext.list_transmissions()
    end

    test "type: travel, existing person, new case, status: done",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      type = :travel
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      person_fixture(tenant, %{
        first_name: first_name,
        last_name: last_name,
        address: %{
          address: "Teststrasse 2"
        }
      })

      view
      |> test_transmission_step(context, %{
        type: type,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name
      })
      |> test_define_people_step_select_person_suggestion(context)
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name,
                 last_name: ^last_name
               }
             ] = CaseContext.list_people()

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: ^type},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid
               }
             ] = CaseContext.list_transmissions()
    end

    test "type: contact_person then travel, existing person, new case, status: done",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      person_fixture(tenant, %{
        first_name: first_name,
        last_name: last_name,
        address: %{
          address: "Teststrasse 2"
        }
      })

      view
      |> test_transmission_step(context, %{
        type: :contact_person,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name
      })
      |> test_define_people_step_select_person_suggestion(context)
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_navigation(context, %{live_action: :index, to_step: "transmission", path_params: []})
      |> test_transmission_step(context, %{
        type: :travel,
        date: date,
        comment: comment
      })
      |> test_navigation(context, %{
        live_action: :index,
        to_step: "action",
        path_params: []
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name,
                 last_name: ^last_name
               }
             ] = CaseContext.list_people()

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: :travel},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid
               }
             ] = CaseContext.list_transmissions()
    end

    test "type: other, existing person, new case, status: done",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      type = :other
      type_other = "test"
      propagator_internal = false
      propagator_ism_id = "883392449292"
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      person_fixture(tenant, %{
        first_name: first_name,
        last_name: last_name,
        address: %{
          address: "Teststrasse 2"
        }
      })

      view
      |> test_transmission_step(context, %{
        type: type,
        type_other: type_other,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name
      })
      |> test_define_people_step_select_person_suggestion(context)
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_disabled_button(context, %{button_id: "#next-button"})

      assert [] = CaseContext.list_cases()

      assert [] = CaseContext.list_transmissions()
    end

    test "type: other, existing person, new case, status: first_contact",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      type = :other
      type_other = "test"
      propagator_internal = false
      propagator_ism_id = "883392449292"
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"

      index = 0

      case_status = :first_contact

      [%{tenant: tenant} | _other_grants] = user.grants

      person_fixture(tenant, %{
        first_name: first_name,
        last_name: last_name,
        address: %{
          address: "Teststrasse 2"
        }
      })

      view
      |> test_transmission_step(context, %{
        type: type,
        type_other: type_other,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name
      })
      |> test_define_people_step_select_person_suggestion(context)
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name,
                 last_name: ^last_name
               }
             ] = CaseContext.list_people()

      assert [
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: ^type, type_other: ^type_other},
                     quarantine_order: nil
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid,
                 propagator_internal: ^propagator_internal,
                 propagator_ism_id: ^propagator_ism_id
               }
             ] = CaseContext.list_transmissions()
    end

    test "type: other, new person, new case, status: first_contact",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      type = :other
      type_other = "test"
      propagator_internal = false
      propagator_ism_id = "883392449292"
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"
      # mobile = "+41 78 724 57 90"
      # email = "karl.muster@gmail.com"

      index = 0

      case_status = :first_contact

      [%{tenant: tenant} | _other_grants] = user.grants

      view
      |> test_transmission_step(context, %{
        type: type,
        type_other: type_other,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name,
        tenant_uuid: tenant.uuid,
        address: %{
          address: "Teststrasse 2"
        }
        # mobile: mobile,
        # email: email
      })
      |> test_define_people_step_submit_person_modal(context, %{})
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name,
                 last_name: ^last_name
                 #  contact_methods: [
                 #    %{type: :mobile, value: ^mobile},
                 #    %{type: :email, value: ^email}
                 #  ]
               }
             ] = CaseContext.list_people()

      assert [
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: ^type, type_other: ^type_other},
                     quarantine_order: nil
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid,
                 propagator_internal: ^propagator_internal,
                 propagator_ism_id: ^propagator_ism_id
               }
             ] = CaseContext.list_transmissions()
    end

    test "type: travel then other, new person, new case, status: done",
         %{conn: conn, user: user} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      type = :other
      type_other = "test"
      propagator_internal = false
      propagator_ism_id = "883392449292"
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name = "Karl"
      last_name = "Muster"
      # mobile = "+41 78 724 57 90"
      # email = "karl.muster@gmail.com"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      view
      |> test_transmission_step(context, %{
        type: :travel,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name,
        last_name: last_name,
        tenant_uuid: tenant.uuid,
        address: %{
          address: "Teststrasse 2"
        }
        # mobile: mobile,
        # email: email
      })
      |> test_define_people_step_submit_person_modal(context, %{})
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_back_button(context, %{to_step: "people"})
      |> test_back_button(context, %{to_step: "transmission"})
      |> test_transmission_step(context, %{
        type: type,
        type_other: type_other,
        propagator_internal: propagator_internal,
        propagator_ism_id: propagator_ism_id,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_next_button(context, %{to_step: "action"})
      |> test_disabled_button(context, %{button_id: "#next-button"})

      assert [] = CaseContext.list_people()

      assert [] = CaseContext.list_cases()

      assert [] = CaseContext.list_transmissions()
    end

    test "import (from Transmissions set propagator_internal and propagator_case) - type: contact_person, new person, new case, status: done",
         %{conn: conn, user: user} = context do
      type = :contact_person
      date = Date.add(Date.utc_today(), -5)
      comment = "Simple comment."

      first_name_propagator = "Karl"
      last_name_propagator = "Muster"

      first_name_person = "John"
      last_name_person = "Doe"
      # mobile = "+41 78 724 57 90"
      # email = "john.doe@gmail.com"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      propagator_case =
        tenant
        |> person_fixture(%{
          first_name: first_name_propagator,
          last_name: last_name_propagator,
          address: %{
            address: "Teststrasse 2"
          }
        })
        |> case_fixture()

      assert {:ok, view, _html} =
               live(
                 conn,
                 Routes.case_create_possible_index_path(conn, :create,
                   propagator_internal: true,
                   propagator_case_uuid: propagator_case.uuid
                 )
               )

      view
      |> test_transmission_step(context, %{
        type: type,
        date: date,
        comment: comment
      })
      |> test_next_button(context, %{to_step: "people"})
      |> test_define_people_step_form(context, %{
        first_name: first_name_person,
        last_name: last_name_person,
        tenant_uuid: tenant.uuid,
        address: %{
          address: "Teststrasse 2"
        }
        # mobile: mobile,
        # email: email
      })
      |> test_define_people_step_submit_person_modal(context, %{})
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context, %{to_step: "summary"})

      assert [
               %Person{
                 uuid: propagator_uuid,
                 first_name: ^first_name_propagator,
                 last_name: ^last_name_propagator
               },
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name_person,
                 last_name: ^last_name_person
                 #  contact_methods: [
                 #    %{type: :mobile, value: ^mobile},
                 #    %{type: :email, value: ^email}
                 #  ]
               }
             ] = CaseContext.list_people()

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: propagator_case_uuid,
                 person_uuid: ^propagator_uuid
               },
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: ^type},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 comment: ^comment,
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid,
                 propagator_case_uuid: ^propagator_case_uuid,
                 propagator_internal: true
               }
             ] = CaseContext.list_transmissions()
    end

    test "import (from possible_index_submission_uuid) - type: contact_person, new person, new case, status: done",
         %{conn: conn, user: user} = context do
      date = ~D[2020-01-25]

      first_name_propagator = "Karl"
      last_name_propagator = "Muster"

      first_name_person = "Corinne"
      last_name_person = "Weber"
      mobile = "+41 78 898 04 51"
      landline = "+41 52 233 06 89"
      email = "corinne.weber@gmx.ch"
      employer = "Unknown GmbH"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      propagator_case =
        tenant
        |> person_fixture(%{
          first_name: first_name_propagator,
          last_name: last_name_propagator,
          address: %{
            address: "Teststrasse 2"
          }
        })
        |> case_fixture()

      possible_index_submission = possible_index_submission_fixture(propagator_case)

      assert {:ok, view, _html} =
               live(
                 conn,
                 Routes.case_create_possible_index_path(conn, :create,
                   possible_index_submission_uuid: possible_index_submission.uuid
                 )
               )

      view
      |> test_transmission_step(context, %{})
      |> test_next_button(context, %{to_step: "people"})
      |> test_edit_possible_index_submission(context, %{
        person: %{tenant_uuid: tenant.uuid}
      })
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context)
      |> assert_redirect(
        Routes.possible_index_submission_index_path(conn, :index, propagator_case.uuid),
        :timer.seconds(5)
      )

      assert [
               %Person{
                 uuid: propagator_uuid,
                 first_name: ^first_name_propagator,
                 last_name: ^last_name_propagator
               },
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name_person,
                 last_name: ^last_name_person,
                 contact_methods: [
                   %{type: :mobile, value: ^mobile},
                   %{type: :landline, value: ^landline},
                   %{type: :email, value: ^email}
                 ],
                 affiliations: [
                   %Affiliation{kind: :employee, unknown_organisation: %{name: ^employer}}
                 ]
               }
             ] = Hygeia.Repo.preload(CaseContext.list_people(), :affiliations)

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: propagator_case_uuid,
                 person_uuid: ^propagator_uuid
               },
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: :contact_person},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid,
                 propagator_case_uuid: ^propagator_case_uuid,
                 propagator_internal: true
               }
             ] = CaseContext.list_transmissions()

      assert [] = CaseContext.list_possible_index_submissions()
    end

    test "import (from possible_index_submission_uuid) infection place is own household - type: contact_person, new person, new case, status: done",
         %{conn: conn, user: user} = context do
      date = ~D[2020-01-25]

      first_name_propagator = "Karl"
      last_name_propagator = "Muster"

      first_name_person = "Corinne"
      last_name_person = "Weber"
      mobile = "+41 78 898 04 51"
      landline = "+41 52 233 06 89"
      email = "corinne.weber@gmx.ch"
      employer = "Unknown GmbH"

      index = 0

      case_status = :done

      [%{tenant: tenant} | _other_grants] = user.grants

      propagator_case =
        tenant
        |> person_fixture(%{
          first_name: first_name_propagator,
          last_name: last_name_propagator,
          address: %{
            address: "Teststrasse 2"
          }
        })
        |> case_fixture()

      propagator_tenant_uuid = propagator_case.tenant_uuid

      possible_index_submission =
        possible_index_submission_fixture(propagator_case, %{
          infection_place: %{type: :hh, address: %{}}
        })

      assert {:ok, view, _html} =
               live(
                 conn,
                 Routes.case_create_possible_index_path(conn, :create,
                   possible_index_submission_uuid: possible_index_submission.uuid
                 )
               )

      view
      |> test_transmission_step(context, %{})
      |> test_next_button(context, %{to_step: "people"})
      |> test_next_button(context, %{to_step: "action"})
      |> test_define_action_step(context, %{
        "index" => index,
        "case" => %{status: case_status}
      })
      |> test_next_button(context)
      |> assert_redirect(
        Routes.possible_index_submission_index_path(conn, :index, propagator_case.uuid),
        :timer.seconds(5)
      )

      assert [
               %Person{
                 uuid: propagator_uuid,
                 first_name: ^first_name_propagator,
                 last_name: ^last_name_propagator
               },
               %Person{
                 uuid: person_uuid,
                 first_name: ^first_name_person,
                 last_name: ^last_name_person,
                 contact_methods: [
                   %{type: :mobile, value: ^mobile},
                   %{type: :landline, value: ^landline},
                   %{type: :email, value: ^email}
                 ],
                 affiliations: [
                   %Affiliation{kind: :employee, unknown_organisation: %{name: ^employer}}
                 ]
               }
             ] = Hygeia.Repo.preload(CaseContext.list_people(), :affiliations)

      {start_date, end_date} = Service.phase_dates(date)

      assert [
               %Case{
                 uuid: propagator_case_uuid,
                 person_uuid: ^propagator_uuid,
                 tenant_uuid: ^propagator_tenant_uuid
               },
               %Case{
                 uuid: case_uuid,
                 person_uuid: ^person_uuid,
                 tenant_uuid: ^propagator_tenant_uuid,
                 status: ^case_status,
                 phases: [
                   %Case.Phase{
                     details: %Case.Phase.PossibleIndex{type: :contact_person},
                     quarantine_order: true,
                     start: ^start_date,
                     end: ^end_date
                   }
                 ]
               }
             ] = CaseContext.list_cases()

      assert [
               %Transmission{
                 date: ^date,
                 recipient_internal: true,
                 recipient_case_uuid: ^case_uuid,
                 propagator_case_uuid: ^propagator_case_uuid,
                 propagator_internal: true
               }
             ] = CaseContext.list_transmissions()

      assert [] = CaseContext.list_possible_index_submissions()
    end
  end
end
