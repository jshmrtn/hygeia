defmodule HygeiaWeb.PolyfilledDateInput do
  @moduledoc false

  use HygeiaWeb, :surface_component

  alias Ecto.UUID
  alias Surface.Components.Form.DateInput

  @doc "The CSS class for the underlying tag"
  prop class, :css_class

  @doc "The form identifier"
  prop form, :form

  @doc "The field name"
  prop field, :atom

  @doc "Options list"
  prop opts, :keyword, default: []

  data input_id, :string

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     assign(socket,
       input_id: "inputdate_" <> UUID.generate()
     )}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    locale = HygeiaCldr.get_locale().language

    ~H"""
    <div id={{ @input_id }} phx-hook="InputDate">
      <DateInput
        lang="de"
        form={{ @form }}
        field={{ @field }}
        class={{ @class }}
        opts={{ @opts ++ [lang: locale] }}
      />
    </div>
    """
  end
end
