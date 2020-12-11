defmodule HygeiaWeb.ErrorView do
  use HygeiaWeb, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  @dialyzer {:no_contracts, {:template_not_found, 2}}
  @spec template_not_found(template :: Phoenix.Template.name(), assigns :: map) :: term
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
