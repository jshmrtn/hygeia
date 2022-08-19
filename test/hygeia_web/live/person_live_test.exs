defmodule HygeiaWeb.PersonLiveTest do
  @moduledoc false

  use Hygeia.DataCase
  use HygeiaWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Person

  @moduletag origin: :test
  @moduletag originator: :noone
  @moduletag log_in: [roles: [:admin]]

  @create_attrs %{
    first_name: "some first_name",
    last_name: "some last_name"
  }
  @update_attrs %{
    first_name: "some updated first_name",
    last_name: "some updated last_name"
  }
  @invalid_attrs %{
    first_name: nil,
    last_name: nil
  }

  defp create_person(tags) do
    [%{tenant: tenant} | _other_grants] = tags.user.grants

    %{person: person_fixture(tenant)}
  end

  describe "Index" do
    setup [:create_person]

    test "lists all people", %{conn: conn, person: person} do
      {:ok, _index_live, html} =
        live(conn, Routes.person_index_path(conn, :index, sort: ["asc_inserted_at"]))

      assert html =~ "Listing People"
      assert html =~ person.first_name
    end

    test "deletes person in listing", %{conn: conn, person: person} do
      {:ok, index_live, _html} =
        live(conn, Routes.person_index_path(conn, :index, sort: ["asc_inserted_at"]))

      assert index_live |> element("#person-#{person.uuid} a[title=Delete]") |> render_click()
      refute has_element?(index_live, "#person-#{person.uuid}")
    end
  end

  describe "Create" do
    test "saves new person", %{conn: conn, user: user} do
      [%{tenant: tenant} | _other_grants] = user.grants

      {:ok, create_live, _html} = live(conn, Routes.person_create_path(conn, :create))

      assert create_live
             |> form("#person-form", person: Map.put(@invalid_attrs, :tenant_uuid, tenant.uuid))
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _view, html} =
        create_live
        |> form("#person-form", person: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Person created successfully"
      assert html =~ "some first_name"
    end
  end

  describe "Base Data" do
    setup [:create_person]

    test "displays person", %{conn: conn, person: person} do
      {:ok, _show_live, html} = live(conn, Routes.person_base_data_path(conn, :show, person))

      assert html =~ person.first_name
    end

    test "updates person within modal", %{conn: conn, person: person} do
      {:ok, edit_live, _html} = live(conn, Routes.person_base_data_path(conn, :edit, person))

      assert edit_live
             |> form("#person-form", person: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert edit_live
             |> form("#person-form", person: %{is_vaccinated: true})
             |> render_change()

      assert render_hook(edit_live, :add_vaccination_shot)
      assert render_hook(edit_live, :add_vaccination_shot)

      assert edit_live
             |> form("#person-form",
               person: %{
                 convalescent_externally: true,
                 vaccination_shots: %{
                   "0" => %{
                     date: "2022-01-02",
                     vaccine_type: :pfizer
                   },
                   "1" => %{
                     date: "2022-01-03",
                     vaccine_type: :other
                   }
                 }
               }
             )
             |> render_change()

      assert edit_live
             |> form("#person-form",
               person: %{
                 vaccination_shots: %{
                   "1" => %{
                     vaccine_type_other: "Pizza"
                   }
                 }
               }
             )
             |> render_change()

      html =
        edit_live
        |> form("#person-form", person: @update_attrs)
        |> render_submit()

      assert_patch(edit_live, Routes.person_base_data_path(conn, :show, person))

      assert html =~ "Person updated successfully"
      assert html =~ "some updated first_name"

      assert %Person{
               first_name: "some updated first_name",
               last_name: "some updated last_name",
               is_vaccinated: true,
               convalescent_externally: true,
               vaccination_shots: [_, _]
             } = person.uuid |> CaseContext.get_person!() |> Repo.preload([:vaccination_shots])
    end

    test "redacts person", %{conn: conn, person: person} do
      {:ok, show_live, _html} = live(conn, Routes.person_base_data_path(conn, :show, person))

      {:ok, _show_live, html} =
        show_live
        |> element("button", "Redact")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Person redacted successfully"
    end

    test "person redact button is disabled if there are unredacted cases", %{
      conn: conn,
      person: person
    } do
      case_fixture(person)

      {:ok, show_live, _html} = live(conn, Routes.person_base_data_path(conn, :show, person))

      assert show_live
             |> element("button", "Redact")
             |> render() =~ "disabled"
    end

    test "person cannot be redacted if new case is added meanwhile", %{conn: conn, person: person} do
      {:ok, show_live, _html} = live(conn, Routes.person_base_data_path(conn, :show, person))

      case_fixture(person)

      {:ok, _show_live, html} =
        show_live
        |> element("button", "Redact")
        |> render_click()
        |> follow_redirect(conn)

      html =~
        "This person can not be redacted because there are unredacted cases associated to it"
    end

    test "reidentifies person", %{conn: conn, person: person} do
      {:ok, show_live, _html} = live(conn, Routes.person_base_data_path(conn, :show, person))

      {:ok, _person} = CaseContext.redact_person(person)

      html =
        show_live
        |> element("button", "Reidentify")
        |> render_click()

      assert html =~ "Reidentify person"

      {:ok, _show_live, html} =
        show_live
        |> form("#redact-person-form", person: %{first_name: "TestFirstName"})
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Person reidentified successfully"
      assert html =~ "TestFirstName"
    end
  end
end
