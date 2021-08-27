defmodule HygeiaWeb.Helpers.Tenant do
  @moduledoc """
  Tenant Helpers
  """

  alias Hygeia.TenantContext.Tenant
  alias HygeiaWeb.Router.Helpers, as: Routes

  defp logo_name(%Tenant{country: nil}), do: nil

  defp logo_name(%Tenant{country: country, subdivision: subdivision}),
    do: [country, subdivision] |> Enum.reject(&is_nil/1) |> Enum.join("-")

  defp logo_root, do: Application.fetch_env!(:hygeia_web, :tenant_logo_root_path)

  defp logo_filename(tenant) do
    tenant
    |> logo_name()
    |> case do
      nil -> []
      name -> Path.wildcard(Path.join(logo_root(), name <> ".*"))
    end
    |> case do
      [] -> nil
      [filename | _rest] -> Path.basename(filename)
    end
  end

  @spec logo_exists?(tenant :: Tenant.t()) :: boolean
  def logo_exists?(tenant), do: logo_filename(tenant) != nil

  @spec logo_uri(
          tenant :: Tenant.t(),
          context :: module() | Plug.Conn.t() | Phoenix.LiveView.Socket.t()
        ) :: String.t()
  def logo_uri(tenant, context),
    do: Routes.static_path(context, "/tenant-logos/#{logo_filename(tenant)}")
end
