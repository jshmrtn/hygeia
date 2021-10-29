defmodule HygeiaWeb.PolimorphicInputs do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import PolymorphicEmbed.HTML.Form
  import Phoenix.HTML.Form, only: [hidden_inputs_for: 1]

  alias Surface.Components.Form.Input.InputContext

  slot default, args: [:form]

  prop field, :string, required: true
  prop type, :atom, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~F"""
    <InputContext assigns={assigns} :let={form: form}>
      <Context
        :for={f <- to_form(form.source, form, @field, @type, Keyword.take(form.options, [:multipart]))}
        put={Surface.Components.Form, form: f}
      >
        {hidden_inputs_for(f)}
        <#slot :args={form: f} />
      </Context>
    </InputContext>
    """
  end
end
