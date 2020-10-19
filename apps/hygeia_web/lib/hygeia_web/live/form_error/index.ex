defmodule HygeiaWeb.FormError do
  @moduledoc false

  use HygeiaWeb, :surface_component

  import HygeiaWeb.ErrorHelpers

  alias Surface.Components.Form.Input.InputContext

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
      <div
        :for={{ error <- Keyword.get_values(form.errors, field) }}
        class="d-block invalid-feedback"
        phx_feedback_for={{ input_id(form, field) }}
      >
        {{ translate_error(error) }}
      </div>
    </InputContext>
    """
  end
end
