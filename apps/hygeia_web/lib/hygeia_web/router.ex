defmodule HygeiaWeb.Router do
  use HygeiaWeb, :router

  # Make sure compilation order is correct
  require HygeiaWeb.Cldr

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HygeiaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Cldr.Plug.AcceptLanguage,
      cldr_backend: HygeiaWeb.Cldr

    plug Cldr.Plug.SetLocale,
      apps: [:cldr, :gettext],
      from: [:session, :accept_language],
      gettext: HygeiaWeb.Gettext,
      cldr: HygeiaWeb.Cldr,
      session_key: "cldr_locale"

    plug :store_locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HygeiaWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/tenants", TenantLive.Index, :index
    live "/tenants/new", TenantLive.Index, :new
    live "/tenants/:id/edit", TenantLive.Index, :edit

    live "/tenants/:id", TenantLive.Show, :show
    live "/tenants/:id/show/edit", TenantLive.Show, :edit

    live "/professions", ProfessionLive.Index, :index
    live "/professions/new", ProfessionLive.Index, :new
    live "/professions/:id/edit", ProfessionLive.Index, :edit

    live "/professions/:id", ProfessionLive.Show, :show
    live "/professions/:id/show/edit", ProfessionLive.Show, :edit

    live "/users", UserLive.Index, :index

    live "/users/:id", UserLive.Show, :show

    live "/people", PersonLive.Index, :index
    live "/people/new", PersonLive.Index, :new
    live "/people/:id/edit", PersonLive.Index, :edit

    live "/people/:id", PersonLive.Show, :show
    live "/people/:id/show/edit", PersonLive.Show, :edit

    live "/cases", CaseLive.Index, :index
    live "/cases/new", CaseLive.Index, :new
    live "/cases/:id/edit", CaseLive.Index, :edit

    live "/cases/:id", CaseLive.Show, :show
    live "/cases/:id/show/edit", CaseLive.Show, :edit

    live "/organisations", OrganisationLive.Index, :index
    live "/organisations/new", OrganisationLive.Index, :new
    live "/organisations/:id/edit", OrganisationLive.Index, :edit

    live "/organisations/:id", OrganisationLive.Show, :show
    live "/organisations/:id/show/edit", OrganisationLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  # scope "/api", HygeiaWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/", HygeiaWeb do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HygeiaTelemetry
    end
  end

  defp store_locale(conn, _params) do
    Plug.Conn.put_session(conn, "cldr_locale", conn.private.cldr_locale.requested_locale_name)
  end
end
