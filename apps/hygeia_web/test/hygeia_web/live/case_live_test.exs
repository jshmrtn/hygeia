defmodule HygeiaWeb.CaseLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import HygeiaWeb.Helpers.Case
  import Phoenix.LiveViewTest

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

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
  end

  describe "Show" do
    setup [:create_case]

    test "displays case", %{conn: conn, case_model: case} do
      {:ok, _show_live, html} = live(conn, Routes.case_base_data_path(conn, :show, case))

      assert html =~ Atom.to_string(case.complexity)
    end
  end

  describe "CreateIndex" do
    test "creates case without duplicate", %{conn: conn} do
      tenant = tenant_fixture()
      tracer_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:tracer]})
      supervisor_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:supervisor]})

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
                       mobile: "+41787245790"
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
                 contact_methods: [%{type: :mobile, value: "+41787245790"}]
               }
             ] = CaseContext.list_people()
    end

    test "blocks create case with duplicate", %{conn: conn} do
      tenant = tenant_fixture()
      tracer_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:tracer]})
      supervisor_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:supervisor]})

      person_fixture(tenant, %{
        first_name: "Max",
        last_name: "Muster",
        contact_methods: [%{type: :mobile, value: "+41787245790"}]
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
                       mobile: "+41787245790"
                     }
                   }
                 }
               )
               |> render_submit()

      refute html =~ "Created Case"
    end

    # TODO: Add Test where duplicate is accepted, refuted and one with import
  end

  describe "CreatePossibleIndex" do
    test "creates case without duplicate", %{conn: conn} do
      tenant = tenant_fixture()
      tracer_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:tracer]})
      supervisor_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:supervisor]})

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
                       mobile: "+41787245790"
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
                 contact_methods: [%{type: :mobile, value: "+41787245790"}]
               }
             ] = CaseContext.list_people()
    end

    test "blocks create case with duplicate", %{conn: conn} do
      tenant = tenant_fixture()
      tracer_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:tracer]})
      supervisor_user = user_fixture(%{iam_sub: Ecto.UUID.generate(), roles: [:supervisor]})

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
    end

    # TODO: Add Test where duplicate is accepted, refuted and one with import
  end
end
