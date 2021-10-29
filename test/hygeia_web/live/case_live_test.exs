# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person

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

  describe "CreatePossibleIndex" do
    test "creates case without duplicate", %{conn: conn, user: user} do
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

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form",
                 create_schema: %{
                   type: :travel,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41 78 724 57 90"
                     }
                   }
                 }
               )
               |> render_submit()

      assert html =~ "Created Case"

      assert [
               %Person{
                 first_name: "Max",
                 last_name: "Muster",
                 contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
               }
             ] = CaseContext.list_people()

      assert [_] = CaseContext.list_cases()
      assert [_] = CaseContext.list_transmissions()
    end

    test "blocks create case with duplicate", %{conn: conn, user: user} do
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

      person_fixture(tenant, %{
        first_name: "Max",
        last_name: "Muster",
        contact_methods: [%{type: :mobile, value: "+41787245790"}]
      })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form",
                 create_schema: %{
                   type: :travel,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41787245790"
                     }
                   }
                 }
               )
               |> render_submit()

      refute html =~ "Created Case"

      assert [_] = CaseContext.list_people()
      assert [] = CaseContext.list_cases()
      assert [] = CaseContext.list_transmissions()
    end

    test "accept create case with duplicate person", %{conn: conn, user: user} do
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

      duplicate_person =
        person_fixture(tenant, %{
          first_name: "Max",
          last_name: "Muster",
          contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
        })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
                   type: :travel,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41 78 724 57 90",
                       accepted_duplicate: true,
                       accepted_duplicate_uuid: duplicate_person.uuid,
                       accepted_duplicate_human_readable_id: duplicate_person.human_readable_id
                     }
                   }
                 }
               })

      assert html =~ "Created Case"

      assert [_] = CaseContext.list_cases()
      assert [_] = CaseContext.list_people()
    end

    test "accept create case with duplicate person, copy address", %{conn: conn, user: user} do
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

      duplicate_person_1 =
        person_fixture(tenant, %{
          first_name: "Max",
          last_name: "Muster",
          address: %{
            address: "Teststrasse 3"
          }
        })

      duplicate_person_2 =
        person_fixture(tenant, %{
          first_name: "Henry",
          last_name: "Muster",
          address: nil
        })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
                   type: :contact_person,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   copy_address_from_propagator: true,
                   propagator_internal: true,
                   propagator_case_uuid: propagator_case.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       accepted_duplicate: true,
                       accepted_duplicate_uuid: duplicate_person_1.uuid,
                       accepted_duplicate_human_readable_id: duplicate_person_1.human_readable_id
                     },
                     1 => %{
                       first_name: "Henry",
                       last_name: "Muster",
                       accepted_duplicate: true,
                       accepted_duplicate_uuid: duplicate_person_2.uuid,
                       accepted_duplicate_human_readable_id: duplicate_person_2.human_readable_id
                     },
                     2 => %{
                       first_name: "Petra",
                       last_name: "Muster"
                     }
                   }
                 }
               })

      assert html =~ "Created 3 Cases"

      assert [_, _, _, _] = CaseContext.list_cases()
      assert [_, _, _, _] = people = CaseContext.list_people()

      assert %Person{address: %Address{address: "Teststrasse 3"}} =
               Enum.find(people, &match?(%Person{first_name: "Max"}, &1))

      assert %Person{address: %Address{address: "Teststrasse 2"}} =
               Enum.find(people, &match?(%Person{first_name: "Henry"}, &1))

      assert %Person{address: %Address{address: "Teststrasse 2"}} =
               Enum.find(people, &match?(%Person{first_name: "Petra"}, &1))
    end

    test "accept create case with duplicate case keeps phases", %{conn: conn, user: user} do
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

      duplicate_person =
        person_fixture(tenant, %{
          first_name: "Max",
          last_name: "Muster",
          contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
        })

      duplicate_case =
        case_fixture(duplicate_person, tracer_user, supervisor_user, %{
          phases: [%{details: %{__type__: :possible_index, type: :travel}}]
        })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
                   type: :travel,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41 78 724 57 90",
                       accepted_duplicate: true,
                       accepted_duplicate_uuid: duplicate_person.uuid,
                       accepted_duplicate_human_readable_id: duplicate_person.human_readable_id,
                       accepted_duplicate_case_uuid: duplicate_case.uuid
                     }
                   }
                 }
               })

      assert html =~ "Created Case"

      assert [%Case{phases: [_]}] = CaseContext.list_cases()
      assert [_] = CaseContext.list_people()
    end

    test "accept create case with duplicate case appends phase", %{conn: conn, user: user} do
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

      duplicate_person =
        person_fixture(tenant, %{
          first_name: "Max",
          last_name: "Muster",
          contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
        })

      duplicate_case =
        case_fixture(duplicate_person, tracer_user, supervisor_user, %{
          phases: [%{details: %{__type__: :possible_index, type: :travel}}]
        })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
                   type: :contact_person,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41 78 724 57 90",
                       accepted_duplicate: true,
                       accepted_duplicate_uuid: duplicate_person.uuid,
                       accepted_duplicate_human_readable_id: duplicate_person.human_readable_id,
                       accepted_duplicate_case_uuid: duplicate_case.uuid
                     }
                   }
                 }
               })

      assert html =~ "Created Case"

      assert [%Case{phases: [_, _]}] = CaseContext.list_cases()
      assert [_] = CaseContext.list_people()
    end

    test "refute create case with duplicate person", %{conn: conn, user: user} do
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

      _duplicate_person =
        person_fixture(tenant, %{
          first_name: "Max",
          last_name: "Muster",
          contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
        })

      assert {:ok, create_live, _html} =
               live(conn, Routes.case_create_possible_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
                   type: :travel,
                   date: Date.add(Date.utc_today(), -5),
                   default_tenant_uuid: tenant.uuid,
                   default_tracer_uuid: tracer_user.uuid,
                   default_supervisor_uuid: supervisor_user.uuid,
                   people: %{
                     0 => %{
                       first_name: "Max",
                       last_name: "Muster",
                       mobile: "+41 78 724 57 90",
                       accepted_duplicate: false
                     }
                   }
                 }
               })

      assert html =~ "Created Case"

      assert [_] = CaseContext.list_cases()
      assert [_, _] = CaseContext.list_people()
    end
  end
end
