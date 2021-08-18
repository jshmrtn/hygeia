defmodule HygeiaWeb.CaseLiveTestHelper do
  import Hygeia.Fixtures

  alias HygeiaWeb.Router.Helpers, as: Routes

  defmacro test_transmission_step_type_travel(context, view) do
    quote do
      %{conn: conn} = unquote(context)

      assert unquote(view)
             |> form("#define-transmission-form",
               define_transmission: %{
                 type: :travel,
                 date: Date.add(Date.utc_today(), -5),
                 comment: "Simple comment."
               }
             )
             |> render_submit()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_transmission_step_type_travel_import(context, view) do
    quote do
      %{conn: conn} = unquote(context)

      assert html =
               unquote(view)
               |> element(".container button[type=submit]")
               |> render()

      refute html =~ "disabled"

      assert unquote(view)
             |> element("#define-transmission-form")
             |> render_submit()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_transmission_step_with_propagator_type_contact_person(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

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

      assert unquote(view)
             |> form("#define-transmission-form")
             |> render_submit(%{
               define_transmission: %{
                 type: :contact_person,
                 date: Date.add(Date.utc_today(), -5),
                 propagator_internal: true,
                 propagator_case_uuid: propagator_case.uuid
               }
             })

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_transmission_step_with_propagator_type_contact_person_import(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

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

      params = %{
        type: :contact_person,
        date: Date.add(Date.utc_today(), -5) |> Date.to_iso8601(),
        propagator_internal: true,
        propagator_case_uuid: propagator_case.uuid
      }

      assert unquote(view)
             |> form("#define-transmission-form")
             |> render_submit()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_transmission_step_with_ext_propagator_type_contact_person(context, view) do
    quote do
      %{conn: conn} = unquote(context)

      assert unquote(view)
             |> form("#define-transmission-form")
             |> render_submit(%{
               define_transmission: %{
                 type: :contact_person,
                 propagator_internal: false,
                 propagator_ism_id: "883392449292",
                 date: Date.add(Date.utc_today(), -5)
               }
             })

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_transmission_step_type_other(context, view) do
    quote do
      %{conn: conn} = unquote(context)

      assert unquote(view)
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

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))
    end
  end

  defmacro test_define_people_step_new_person_new_case(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

      assert unquote(view)
             |> form("#search-people-form",
               search: %{
                 first_name: "Karl",
                 last_name: "Muster",
                 mobile: "+41 78 724 57 90",
                 email: "karl.muster@gmail.com"
               }
             )
             |> render_submit()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :new, "people"))

      # Inside the create person modal

      [%{tenant: tenant} | _other_grants] = user.grants

      assert unquote(view)
             |> form("#create-person-form")
             |> render_submit(
               person: %{
                 tenant_uuid: tenant.uuid,
                 address: %{
                   address: "Teststrasse 2"
                 }
               }
             )

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "people"))

      # Back in Define People step

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "options"))
    end
  end

  defmacro test_define_people_step_existing_person_new_case(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

      [%{tenant: tenant} | _other_grants] = user.grants

      person =
        person_fixture(tenant, %{
          first_name: "Karl",
          last_name: "Muster",
          address: %{
            address: "Teststrasse 2"
          }
        })

      assert unquote(view)
             |> element("#search-people-form")
             |> render_change(%{
               search: %{
                 first_name: "Karl",
                 last_name: "Muster"
               }
             })

      assert unquote(view)
             |> element("#suggestions button")
             |> render_click()

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "options"))
    end
  end

  defmacro test_define_people_step_existing_person_existing_case(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

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

      case = case_fixture(person, tracer_user, supervisor_user)

      assert unquote(view)
             |> element("#search-people-form")
             |> render_change(%{
               search: %{
                 first_name: "Karl",
                 last_name: "Muster"
               }
             })

      assert unquote(view)
             |> element("#suggestion-cases button")
             |> render_click()

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "options"))
    end
  end

  defmacro test_define_options_step_case_status_first_contact(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

      assert html =
               unquote(view)
               |> element("#define-options-form")
               |> render_change(%{
                 "index" => "0",
                 "case" => %{status: :first_contact}
               })

      assert html =~ "First contact"

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(
        unquote(view),
        Routes.case_create_possible_index_path(conn, :index, "reporting")
      )
    end
  end

  defmacro test_define_options_step_case_status_done(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

      assert html =
               unquote(view)
               |> element("#define-options-form")
               |> render_change(%{
                 "index" => "0",
                 "case" => %{status: :done}
               })

      assert html =~ "Done"

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(
        unquote(view),
        Routes.case_create_possible_index_path(conn, :index, "reporting")
      )
    end
  end

  defmacro test_reporting_step_all_contact_methods(context, view) do
    quote do
      %{conn: conn, user: user} = unquote(context)

      assert unquote(view)
             |> element("#next-button")
             |> render_click()

      assert_patch(unquote(view), Routes.case_create_possible_index_path(conn, :index, "summary"))
    end
  end
end
