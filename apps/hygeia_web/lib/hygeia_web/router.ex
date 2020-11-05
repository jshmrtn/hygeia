defmodule HygeiaWeb.Router do
  use HygeiaWeb, :router

  import Phoenix.LiveDashboard.Router
  import PlugDynamic.Builder

  # Make sure compilation order is correct
  require HygeiaCldr

  @debug_errors Application.compile_env(:hygeia_web, [HygeiaWeb.Endpoint, :debug_errors], false)
  @code_reloading Application.compile_env(
                    :hygeia_web,
                    [HygeiaWeb.Endpoint, :code_reloader],
                    false
                  )
  @frame_src if(@code_reloading, do: ~w('self'), else: ~w('none'))
  @style_src if(@debug_errors, do: ~w('unsafe-inline'), else: ~w())

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HygeiaWeb.LayoutView, :root}
    plug :put_secure_browser_headers

    plug Cldr.Plug.AcceptLanguage,
      cldr_backend: HygeiaCldr

    plug Cldr.Plug.SetLocale,
      apps: [:cldr, :gettext],
      from: [:session, :accept_language],
      gettext: HygeiaGettext,
      cldr: HygeiaCldr,
      session_key: "cldr_locale"

    dynamic_plug PlugContentSecurityPolicy do
      sso_origins =
        :ueberauth
        |> Application.fetch_env!(UeberauthOIDC)
        |> Enum.filter(&match?({_name, [_head | _tail]}, &1))
        |> Enum.map(&elem(&1, 1))
        |> Enum.map(&Keyword.fetch(&1, :issuer_or_config_endpoint))
        |> Enum.filter(&match?({:ok, _endpoint}, &1))
        |> Enum.map(&elem(&1, 1))
        |> Enum.map(
          &(&1
            |> URI.parse()
            |> Map.put(:path, nil)
            |> Map.put(:query, nil)
            |> URI.to_string())
        )

      [
        nonces_for: [:script_src, :style_src],
        directives: %{
          default_src: ~w('none'),
          script_src: ~w(),
          style_src: @style_src,
          img_src: ~w('self' data:),
          font_src: ~w('self' data:),
          connect_src: ~w('self'),
          media_src: ~w('none'),
          object_src: ~w('none'),
          prefetch_src: ~w('none'),
          child_src: ~w('none'),
          frame_src: @frame_src,
          worker_src: ~w('none'),
          frame_ancestors: ~w('none'),
          form_action: ["'self'" | sso_origins],
          upgrade_insecure_requests: ~w(),
          block_all_mixed_content: ~w(),
          sandbox: ~w(allow-forms allow-scripts allow-modals allow-same-origin allow-downloads),
          base_uri: ~w('none'),
          manifest_src: ~w('none')
        }
      ]
    end

    plug :store_locale

    plug HygeiaWeb.Plug.SetupVersioning
  end

  pipeline :csrf do
    plug :protect_from_forgery
  end

  pipeline :protected do
    plug HygeiaWeb.Plug.RequireAuthentication
  end

  pipeline :protected_webmaster do
    plug HygeiaWeb.Plug.HasRole, :webmaster
  end

  scope "/auth", HygeiaWeb do
    pipe_through [:browser, :csrf]

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback

    delete "/", AuthController, :delete
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser, :csrf, :protected]

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
    live "/people/:cursor_direction/:cursor", PersonLive.Index, :index

    live "/people/new", PersonLive.Create, :create
    live "/people/:id", PersonLive.BaseData, :show
    live "/people/:id/show/edit", PersonLive.BaseData, :edit

    live "/cases/new/index", CaseLive.CreateIndex, :create
    live "/cases/new/possible-index", CaseLive.CreatePossibleIndex, :create

    live "/cases/:id", CaseLive.BaseData, :show
    live "/cases/:id/show/edit", CaseLive.BaseData, :edit

    live "/cases/:id/transmissions", CaseLive.Transmissions, :show
    live "/cases/:id/protocol", CaseLive.Protocol, :show

    live "/cases/", CaseLive.Index, :index
    live "/cases/:cursor_direction/:cursor", CaseLive.Index, :index

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

    get "/pdf/isolation/:case_uuid/:phase_uuid", PdfController, :isolation_confirmation
    get "/pdf/quarantine/:case_uuid/:phase_uuid", PdfController, :quarantine_confirmation
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser]
    put "/uploads/:id", UploadController, :upload
  end

  scope "/dashboard" do
    pipe_through [:browser, :csrf, :protected, :protected_webmaster]

    live_dashboard "/",
      metrics: {HygeiaTelemetry, :dashboard_metrics},
      ecto_repos: [Hygeia.Repo],
      env_keys: [
        "WEB_PORT",
        "WEB_EXTERNAL_PORT",
        "WEB_EXTERNAL_HOST",
        "WEB_EXTERNAL_SCHEME",
        "WEB_IAM_ISSUER",
        "WEB_IAM_CLIENT_ID",
        "API_PORT",
        "API_EXTERNAL_PORT",
        "API_EXTERNAL_HOST",
        "API_EXTERNAL_SCHEME",
        "DATABASE_SSL",
        "DATABASE_USER",
        "DATABASE_NAME",
        "DATABASE_PORT",
        "DATABASE_HOST",
        "DATABASE_POOL_SIZE",
        "RELEASE_NAME",
        "KUBERNETES_POD_SELECTOR",
        "KUBERNETES_NAMESPACE",
        "METRICS_PORT"
      ],
      allow_destructive_actions: true,
      csp_nonce_assign_key: %{
        img: :img_src_nonce,
        style: :style_src_nonce,
        script: :script_src_nonce
      }
  end

  defp store_locale(conn, _params) do
    Plug.Conn.put_session(conn, "cldr_locale", conn.private.cldr_locale.requested_locale_name)
  end
end
