defmodule HygeiaWeb.Helpers.Versioning do
  @moduledoc false

  import HygeiaGettext

  alias Hygeia.Helpers.Versioning

  @spec translate_versioning_origin(origin :: Versioning.origin()) :: String.t()
  def translate_versioning_origin(:web), do: gettext("Website")

  def translate_versioning_origin(:case_close_email_job),
    do: gettext("Automated Case Close Email")

  def translate_versioning_origin(:user_sync_job), do: gettext("User Sync")
  def translate_versioning_origin(:api), do: gettext("API")
end
