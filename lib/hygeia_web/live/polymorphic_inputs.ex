defmodule HygeiaWeb.PolimorphicInputs do
  @moduledoc false

  use HygeiaWeb, :surface_live_component

  import PolymorphicEmbed.HTML.Form
  import Phoenix.HTML.Form, only: [hidden_inputs_for: 1]

  alias Surface.Components.Form

  slot default, arg: %{form: :form}

  prop form, :form, from_context: {Form, :form}
  prop field, :string, required: true
  prop type, :atom, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~F"""
    <div>
      <div :for={f <- to_form(@form.source, @form, @field, @type, Keyword.take(@form.options, [:multipart]))}>
        {hidden_inputs_for(f)}
        <#slot {@default, form: f} context_put={Form, form: f} />
      </div>
    </div>
    """
  end
end
