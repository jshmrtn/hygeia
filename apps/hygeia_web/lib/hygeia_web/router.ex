defmodule HygeiaWeb.Router do
  use HygeiaWeb, :router

  import Phoenix.LiveDashboard.Router

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

    plug HygeiaWeb.Plug.SetupVersioning
  end

  pipeline :protected do
    plug HygeiaWeb.Plug.RequireAuthentication
  end

  pipeline :protected_webmaster do
    plug HygeiaWeb.Plug.HasRole, :webmaster
  end

  scope "/auth", HygeiaWeb do
    pipe_through [:browser]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback

    delete "/", AuthController, :delete
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser, :protected]

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

    live "/statistics", StatisticsLive.Index, :index

    live "/organisations/:id/positions/new", OrganisationLive.Show, :position_new

    live "/organisations/:id/positions/:position_id/edit",
         OrganisationLive.Show,
         :position_edit
  end

  scope "/dashboard" do
    pipe_through [:browser, :protected, :protected_webmaster]

    live_dashboard "/", metrics: HygeiaTelemetry, ecto_repos: [Hygeia.Repo]
  end

  defp store_locale(conn, _params) do
    Plug.Conn.put_session(conn, "cldr_locale", conn.private.cldr_locale.requested_locale_name)
  end
end
