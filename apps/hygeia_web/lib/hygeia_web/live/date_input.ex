defmodule HygeiaWeb.DateInput do
  @moduledoc false

  use Surface.Components.Form.Input

  import HygeiaGettext
  import Phoenix.HTML.Form, only: [date_input: 3, date_select: 3]
  import Surface.Components.Form.Utils

  prop input_opts, :keyword, default: []
  prop select_opts, :keyword, default: []

  @impl Phoenix.LiveComponent
  def render(assigns) do
    year_now = Date.utc_today().year

    helper_opts = props_to_opts(assigns)
    attr_opts = props_to_attr_opts(assigns, [:value, class: get_config(:default_class)])
    event_opts = events_to_opts(assigns)

    select_opts =
      assigns.select_opts
      # Classes
      |> Keyword.update(
        :year,
        [class: "form-control year"],
        &Keyword.put_new(&1, :class, "form-control year")
      )
      |> Keyword.update(
        :month,
        [class: "form-control month"],
        &Keyword.put_new(&1, :class, "form-control month")
      )
      |> Keyword.update(
        :day,
        [class: "form-control day"],
        &Keyword.put_new(&1, :class, "form-control day")
      )
      # Options
      |> Keyword.update!(:year, &Keyword.put_new(&1, :options, year_now..(year_now - 100)))
      |> Keyword.update!(:month, &Keyword.put_new(&1, :options, months()))

    select_opts =
      if assigns.opts[:disabled] do
        select_opts
        |> Keyword.update!(:year, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:month, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:day, &Keyword.put_new(&1, :disabled, true))
      else
        select_opts
      end

    ~H"""
    <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
      <Context get={{ HygeiaWeb, browser_features: browser_features }}>
        <div :if={{ browser_features["date_input"] != false }}>
          {{ date_input(form, field, helper_opts ++ attr_opts ++ @opts ++ @input_opts ++ event_opts) }}
        </div>
        <div :if={{ browser_features["date_input"] == false }} class="date-select">
          {{ date_select(
            form,
            field,
            helper_opts ++ attr_opts ++ @opts ++ select_opts ++ event_opts
          ) }}
        </div>
      </Context>
    </InputContext>
    """
  end

  defp months,
    do: [
      {gettext("January"), "1"},
      {gettext("February"), "2"},
      {gettext("March"), "3"},
      {gettext("April"), "4"},
      {gettext("May"), "5"},
      {gettext("June"), "6"},
      {gettext("July"), "7"},
      {gettext("August"), "8"},
      {gettext("September"), "9"},
      {gettext("October"), "10"},
      {gettext("November"), "11"},
      {gettext("December"), "12"}
    ]
end
