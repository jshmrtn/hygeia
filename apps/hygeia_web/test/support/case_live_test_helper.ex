defmodule HygeiaWeb.CaseLiveTestHelper do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias HygeiaWeb.Router.Helpers, as: Routes

  @spec test_next_button(view :: LiveViewTest.t(), context :: map(), params :: map()) ::
          LiveViewTest.t()
  def test_next_button(view, context, params)

  def test_next_button(view, %{conn: conn}, %{to_step: to_step}) do
    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, to_step))
    view
  end

  @spec test_back_button(view :: LiveViewTest.t(), context :: map(), params :: map()) ::
          LiveViewTest.t()
  def test_back_button(view, context, params)

  def test_back_button(view, %{conn: conn}, %{to_step: to_step}) do
    assert view
           |> element("#back-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, to_step))
    view
  end

  @spec test_disabled_button(view :: LiveViewTest.t(), context :: map(), params :: map()) ::
          LiveViewTest.t()
  def test_disabled_button(view, _context, %{button_id: button_id}) do
    assert_raise(ArgumentError, fn ->
      view
      |> element(button_id)
      |> render_click()
    end)
  end

  @spec test_navigation(view :: LiveViewTest.t(), context :: map(), params :: map()) ::
          LiveViewTest.t()
  def test_navigation(view, context, params)

  def test_navigation(view, %{conn: conn}, %{
        live_action: live_action,
        to_step: to_step,
        path_params: path_params
      }) do
    assert render_patch(
             view,
             Routes.case_create_possible_index_path(conn, live_action, to_step, path_params)
           )

    assert_patch(
      view,
      Routes.case_create_possible_index_path(conn, live_action, to_step, path_params)
    )

    view
  end

  @spec test_transmission_step(view :: LiveViewTest.t(), context :: map(), params :: map()) ::
          LiveViewTest.t()
  def test_transmission_step(view, context, params)

  def test_transmission_step(view, _context, params) do
    assert view
           |> form("#define-transmission-form")
           |> render_change(define_transmission: params)

    view
  end

  @spec test_transmission_step_import(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_transmission_step_import(view, context) do
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

  @spec test_define_people_step_search(
          view :: LiveViewTest.t(),
          context :: map(),
          params :: map()
        ) ::
          LiveViewTest.t()
  def test_define_people_step_search(view, _context, params) do
    assert view
           |> form("#search-people-form",
             search: params
           )
           |> render_change()

    view
  end

  @spec test_define_people_step_create_person_modal(
          view :: LiveViewTest.t(),
          context :: map(),
          params :: map()
        ) ::
          LiveViewTest.t()
  def test_define_people_step_create_person_modal(view, context, params)

  def test_define_people_step_create_person_modal(view, %{conn: conn}, params) do
    assert view
           |> element("#search-people-form")
           |> render_submit()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :new, "people"))
    view
  end

  @spec test_define_people_step_submit_person_modal(
          view :: LiveViewTest.t(),
          context :: map(),
          params :: map()
        ) ::
          LiveViewTest.t()
  def test_define_people_step_submit_person_modal(view, context, params)

  def test_define_people_step_submit_person_modal(view, %{conn: conn}, params) do
    assert view
           |> form("#create-person-form")
           |> render_submit(person: params)

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "people"))
    view
  end

  @spec test_define_people_step_select_person_suggestion(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_define_people_step_select_person_suggestion(view, context)

  def test_define_people_step_select_person_suggestion(view, _context) do
    assert view
           |> element("#suggestions button")
           |> render_click()

    view
  end

  @spec test_define_people_step_select_case_suggestion(
          view :: LiveViewTest.t(),
          context :: map()
        ) :: LiveViewTest.t()
  def test_define_people_step_select_case_suggestion(view, context)

  def test_define_people_step_select_case_suggestion(view, _context) do
    assert view
           |> element("#suggestion-cases button")
           |> render_click()

    view
  end

  @spec test_define_options_step(
          view :: LiveViewTest.t(),
          context :: map(),
          params :: map()
        ) :: LiveViewTest.t()
  def test_define_options_step(view, context, params)

  def test_define_options_step(view, _context, params) do
    assert view
           |> element("#define-options-form")
           |> render_change(params)

    view
  end

  @spec test_reporting_step(view :: LiveViewTest.t(), context :: map()) ::
          LiveViewTest.t()
  def test_reporting_step(view, context) do
    %{conn: conn} = context

    assert view
           |> element("#next-button")
           |> render_click()

    assert_patch(view, Routes.case_create_possible_index_path(conn, :index, "summary"))
    view
  end
end
