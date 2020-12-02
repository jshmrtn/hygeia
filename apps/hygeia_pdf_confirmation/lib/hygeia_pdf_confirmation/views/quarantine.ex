defmodule HygeiaPdfConfirmation.QuarantineView do
  @moduledoc false

  use Phoenix.View, root: "lib/hygeia_pdf_confirmation/templates"

  import Phoenix.HTML
  import Phoenix.HTML.Tag

  alias Hygeia.CaseContext.Address
end
