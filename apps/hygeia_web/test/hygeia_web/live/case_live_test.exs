# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  import HygeiaWeb.CaseLiveTestHelper

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

  @moduletag :case_live
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
      assert {:error, {:live_redirect, %{to: path}}} =
               live(
                 conn,
                 Routes.case_create_possible_index_path(conn, :index, "reporting")
               )
    end
  end

  describe "CreatePossibleIndex - Define Transmission step" do
    test "submit with type: travel", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)
    end

    test "submit with type: travel, imported from params", %{conn: conn} = context do
      params = %{
        "type" => "travel",
        "date" => Date.add(Date.utc_today(), -5) |> Date.to_string(),
        "comment" => "Simple comment."
      }

      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create, params))

      test_transmission_step_type_travel_import(context, view)
    end

    test "submit with propagator and type: contact_person", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_with_propagator_type_contact_person(context, view)
    end

    # test "submit with propagator and type: contact_person, imported_from_params", %{conn: conn} = context do

    #   assert {:ok, view, _html} =
    #     live(conn, Routes.case_create_possible_index_path(conn, :create))

    #   test_transmission_step_with_propagator_type_contact_person_import(context, view)
    # end

    test "submit with external propagator and type: contact_person", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_with_ext_propagator_type_contact_person(context, view)
    end

    test "submit with type: other and type_other", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_other(context, view)
    end
  end

  describe "CreatePossibleIndex - Define People step" do
    test "submit with new person, new case", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_new_person_new_case(context, view)
    end

    test "submit with existing person, new case", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_existing_person_new_case(context, view)
    end

    test "submit with existing person, existing case", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_existing_person_existing_case(context, view)
    end
  end

  describe "CreatePossibleIndex - Define Options step" do
    test "submit with case status, supervisor, tracer with new person, new case",
         %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_new_person_new_case(context, view)

      test_define_options_step_case_status_first_contact(context, view)
    end
  end

  describe "CreatePossibleIndex" do
    test "type: travel, new person, new case, status: first_contact", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_new_person_new_case(context, view)

      test_define_options_step_case_status_first_contact(context, view)

      test_reporting_step_all_contact_methods(context, view)

      assert [
               %Person{
                 first_name: "Karl",
                 last_name: "Muster",
                 contact_methods: [
                   %{type: :mobile, value: "+41 78 724 57 90"},
                   %{type: :email, value: "karl.muster@gmail.com"}
                 ]
               }
             ] = CaseContext.list_people()

      assert [_] = CaseContext.list_cases()
      assert [_] = CaseContext.list_transmissions()
    end

    test "type: travel, existing person, new case, status: done", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_travel(context, view)

      test_define_people_step_existing_person_new_case(context, view)

      test_define_options_step_case_status_done(context, view)

      test_reporting_step_all_contact_methods(context, view)

      assert [
               %Person{
                 first_name: "Karl",
                 last_name: "Muster"
               }
             ] = CaseContext.list_people()

      assert [_] = CaseContext.list_cases()
      assert [_] = CaseContext.list_transmissions()
    end

    test "type: other, new person, new case, status: done", %{conn: conn} = context do
      assert {:ok, view, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      test_transmission_step_type_other(context, view)

      test_define_people_step_new_person_new_case(context, view)

      test_define_options_step_case_status_done(context, view)

      test_reporting_step_all_contact_methods(context, view)

      assert [
               %Person{
                 first_name: "Karl",
                 last_name: "Muster"
               }
             ] = CaseContext.list_people()

      assert [_] = CaseContext.list_cases()
      assert [_] = CaseContext.list_transmissions()
    end
  end
end
