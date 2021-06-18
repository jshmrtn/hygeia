defmodule HygeiaWeb.DateTimeLocalInput do
  @moduledoc false

  use Surface.Components.Form.Input

  import HygeiaGettext
  import Phoenix.HTML.Form, only: [datetime_local_input: 3, datetime_select: 3]
  import Surface.Components.Utils, only: [events_to_opts: 1]
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
      |> Keyword.update(
        :hour,
        [class: "form-control hour"],
        &Keyword.put_new(&1, :class, "form-control hour")
      )
      |> Keyword.update(
        :minute,
        [class: "form-control minute"],
        &Keyword.put_new(&1, :class, "form-control minute")
      )
      |> update_if_exists(:second, &Keyword.put_new(&1, :class, "form-control second"))
      # Options
      |> Keyword.update!(:year, &Keyword.put_new(&1, :options, year_now..(year_now - 100)))
      |> Keyword.update!(:month, &Keyword.put_new(&1, :options, months()))

    select_opts =
      if assigns.opts[:disabled] do
        select_opts
        |> Keyword.update!(:year, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:month, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:day, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:hour, &Keyword.put_new(&1, :disabled, true))
        |> Keyword.update!(:minute, &Keyword.put_new(&1, :disabled, true))
        |> update_if_exists(:second, &Keyword.put_new(&1, :disabled, true))
      else
        select_opts
      end

    ~F"""
    <InputContext assigns={assigns} :let={form: form, field: field}>
      <Context get={HygeiaWeb, browser_features: browser_features}>
        {if browser_features["datetime_local_input"] != false,
          do:
            datetime_local_input(
              form,
              field,
              helper_opts ++ attr_opts ++ @opts ++ @input_opts ++ event_opts
            )}

        <div :if={browser_features["datetime_local_input"] == false} class="datetime-select">
          {datetime_select(
            form,
            field,
            helper_opts ++ attr_opts ++ @opts ++ select_opts ++ event_opts
          )}
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

  defp update_if_exists(keywords, key, callback) do
    if Keyword.has_key?(keywords, key) do
      Keyword.update!(keywords, key, callback)
    else
      keywords
    end
  end
end
