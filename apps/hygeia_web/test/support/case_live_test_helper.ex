defmodule HygeiaWeb.CaseLiveTestHelper do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.LiveViewTest
  import Hygeia.Fixtures

  alias HygeiaWeb.Router.Helpers, as: Routes

  @spec test_transmission_step_type_travel(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_transmission_step_type_travel(view, context) do
    %{conn: conn} = context

    assert view
           |> form("#define-transmission-form",
             define_transmission: %{
               type: :travel,
               date: Date.add(Date.utc_today(), -5),
               comment: "Simple comment."
             }
           )
           |> render_submit()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_transmission_step_type_travel_import(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_transmission_step_type_travel_import(view, context) do
    %{conn: conn} = context

    assert html =
             view
             |> element(".container button[type=submit]")
             |> render()

    refute html =~ "disabled"

    assert view
           |> element("#define-transmission-form")
           |> render_submit()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_transmission_step_with_propagator_type_contact_person(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_transmission_step_with_propagator_type_contact_person(view, context) do
    %{conn: conn, user: user} = context

    [%{tenant: tenant} | _other_grants] = user.grants

    tracer_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
      })

    supervisor_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
      })

    propagator =
      person_fixture(tenant, %{
        first_name: "Karl",
        last_name: "Muster",
        address: %{
          address: "Teststrasse 2"
        }
      })

    propagator_case = case_fixture(propagator, tracer_user, supervisor_user)

    assert view
           |> form("#define-transmission-form")
           |> render_submit(%{
             define_transmission: %{
               type: :contact_person,
               date: Date.add(Date.utc_today(), -5),
               propagator_internal: true,
               propagator_case_uuid: propagator_case.uuid
             }
           })

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_transmission_step_with_propagator_type_contact_person_import(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_transmission_step_with_propagator_type_contact_person_import(view, context) do
    %{conn: conn, user: user} = context

    [%{tenant: tenant} | _other_grants] = user.grants

    tracer_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
      })

    supervisor_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
      })

    propagator =
      person_fixture(tenant, %{
        first_name: "Karl",
        last_name: "Muster",
        address: %{
          address: "Teststrasse 2"
        }
      })

    case_fixture(propagator, tracer_user, supervisor_user)

    # params = %{
    #   type: :contact_person,
    #   date: Date.add(Date.utc_today(), -5) |> Date.to_iso8601(),
    #   propagator_internal: true,
    #   propagator_case_uuid: propagator_case.uuid
    # }

    assert view
           |> form("#define-transmission-form")
           |> render_submit()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_transmission_step_with_ext_propagator_type_contact_person(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_transmission_step_with_ext_propagator_type_contact_person(view, context) do
    %{conn: conn} = context

    assert view
           |> form("#define-transmission-form")
           |> render_submit(%{
             define_transmission: %{
               type: :contact_person,
               propagator_internal: false,
               propagator_ism_id: "883392449292",
               date: Date.add(Date.utc_today(), -5)
             }
           })

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_transmission_step_type_other(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_transmission_step_type_other(view, context) do
    %{conn: conn} = context

    assert view
           |> form("#define-transmission-form")
           |> render_submit(%{
             define_transmission: %{
               type: :other,
               type_other: "test",
               propagator_internal: false,
               propagator_ism_id: "883392449292",
               date: Date.add(Date.utc_today(), -5)
             }
           })

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_define_people_step_new_person_new_case(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_define_people_step_new_person_new_case(view, context) do
    %{conn: conn, user: user} = context

    assert view
           |> form("#search-people-form",
             search: %{
               first_name: "Karl",
               last_name: "Muster",
               mobile: "+41 78 724 57 90",
               email: "karl.muster@gmail.com"
             }
           )
           |> render_submit()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :new, "people"))

    # Inside the create person modal

    [%{tenant: tenant} | _other_grants] = user.grants

    assert view
           |> form("#create-person-form")
           |> render_submit(
             person: %{
               tenant_uuid: tenant.uuid,
               address: %{
                 address: "Teststrasse 2"
               }
             }
           )

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))

    # Back in Define People step

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "options"))
    view
  end

  @spec test_define_people_step_existing_person_new_case(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_define_people_step_existing_person_new_case(view, context) do
    %{conn: conn, user: user} = context

    [%{tenant: tenant} | _other_grants] = user.grants

    person_fixture(tenant, %{
      first_name: "Karl",
      last_name: "Muster",
      address: %{
        address: "Teststrasse 2"
      }
    })

    assert view
           |> element("#search-people-form")
           |> render_change(%{
             search: %{
               first_name: "Karl",
               last_name: "Muster"
             }
           })

    assert view
           |> element("#suggestions button")
           |> render_click()

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "options"))
    view
  end

  @spec test_define_people_step_existing_person_existing_case(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_define_people_step_existing_person_existing_case(view, context) do
    %{conn: conn, user: user} = context

    [%{tenant: tenant} | _other_grants] = user.grants

    tracer_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :tracer, tenant_uuid: tenant.uuid}]
      })

    supervisor_user =
      user_fixture(%{
        iam_sub: Ecto.UUID.generate(),
        grants: [%{role: :supervisor, tenant_uuid: tenant.uuid}]
      })

    person =
      person_fixture(tenant, %{
        first_name: "Karl",
        last_name: "Muster",
        address: %{
          address: "Teststrasse 2"
        }
      })

    case_fixture(person, tracer_user, supervisor_user)

    assert view
           |> element("#search-people-form")
           |> render_change(%{
             search: %{
               first_name: "Karl",
               last_name: "Muster"
             }
           })

    assert view
           |> element("#suggestion-cases button")
           |> render_click()

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "options"))
    view
  end

  @spec test_define_options_step_case_status_first_contact(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_define_options_step_case_status_first_contact(view, context) do
    %{conn: conn} = context

    assert html =
             view
             |> element("#define-options-form")
             |> render_change(%{
               "index" => "0",
               "case" => %{status: :first_contact}
             })

    assert html =~ "First contact"

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(
      view,
      Routes.case_create_possible_index_path(conn, :index, "reporting")
    )

    view
  end

  @spec test_define_options_step_case_status_done(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_define_options_step_case_status_done(view, context) do
    %{conn: conn} = context

    assert html =
             view
             |> element("#define-options-form")
             |> render_change(%{
               "index" => "0",
               "case" => %{status: :done}
             })

    assert html =~ "Done"

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(
      view,
      Routes.case_create_possible_index_path(conn, :index, "reporting")
    )

    view
  end

  @spec test_reporting_step_all_contact_methods(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_reporting_step_all_contact_methods(view, context) do
    %{conn: conn} = context

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "summary"))
    view
  end
end
