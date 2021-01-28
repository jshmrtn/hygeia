# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaWeb.Helpers.Case
  import Phoenix.LiveViewTest

  alias Hygeia.CaseContext
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
      assert html =~ case_complexity_translation(case.complexity)
    end
  end

  describe "Show" do
    setup [:create_case]

    test "displays case", %{conn: conn, case_model: case} do
      {:ok, _show_live, html} = live(conn, Routes.case_base_data_path(conn, :show, case))

      assert html =~ Atom.to_string(case.complexity)
    end
  end

  describe "CreateIndex" do
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

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form",
                 create_schema: %{
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

      assert [_] = CaseContext.list_cases()

      assert [
               %Person{
                 first_name: "Max",
                 last_name: "Muster",
                 contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
               }
             ] = CaseContext.list_people()
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
        contact_methods: [%{type: :mobile, value: "+41 78 724 57 90"}]
      })

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form",
                 create_schema: %{
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

      refute html =~ "Created Case"

      assert [] = CaseContext.list_cases()
      assert [_] = CaseContext.list_people()
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

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
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
          phases: [%{details: %{__type__: :index}}]
        })

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
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

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
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

      assert [
               %Case{
                 phases: [
                   %Case.Phase{details: %Case.Phase.PossibleIndex{}},
                   %Case.Phase{details: %Case.Phase.Index{}}
                 ]
               }
             ] = CaseContext.list_cases()

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

      assert {:ok, create_live, _html} = live(conn, Routes.case_create_index_path(conn, :create))

      assert html =
               create_live
               |> form("#case-create-form")
               |> render_submit(%{
                 create_schema: %{
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
                   date: "2020-10-17",
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
                   date: ~D[2020-10-17],
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
                   date: ~D[2020-10-17],
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
                   date: ~D[2020-10-17],
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
                   date: ~D[2020-10-17],
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
                   date: ~D[2020-10-17],
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
