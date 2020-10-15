defmodule HygeiaWeb.Router do
  use HygeiaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HygeiaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HygeiaWeb do
    pipe_through :browser

    live "/", PageLive, :index
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
    end
  end
end
