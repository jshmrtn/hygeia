defmodule HygeiaWeb.Router do
  use HygeiaWeb, :router
  import PlugDynamic.Builder

  import Phoenix.LiveDashboard.Router

  # Make sure compilation order is correct
  require HygeiaCldr

  @debug_errors Application.compile_env(:hygeia, [HygeiaWeb.Endpoint, :debug_errors], false)
  @code_reloading Application.compile_env(
                    :hygeia,
                    [HygeiaWeb.Endpoint, :code_reloader],
                    false
                  )
  @frame_src if(@code_reloading, do: ~w('self'), else: ~w())
  @style_src if(@debug_errors, do: ~w('unsafe-inline'), else: ~w())

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_root_layout, {HygeiaWeb.LayoutView, :root}
    plug :put_secure_browser_headers

    plug Cldr.Plug.AcceptLanguage,
      cldr_backend: HygeiaCldr

    plug Cldr.Plug.SetLocale,
      apps: [:cldr, :gettext],
      from: [:session, :accept_language],
      gettext: HygeiaGettext,
      cldr: HygeiaCldr

    plug Cldr.Plug.PutSession

    dynamic_plug PlugContentSecurityPolicy, reevaluate: :first_usage do
      URI.default_port("wss", 443)
      URI.default_port("ws", 80)

      home_url = URI.parse(HygeiaWeb.Endpoint.url())

      ws_url =
        home_url
        |> Map.update!(:scheme, fn
          "http" -> "ws"
          "https" -> "wss"
        end)
        |> Map.put(:path, "")
        |> URI.to_string()

      directives = %{
        default_src: ~w('none'),
        script_src: ~w(),
        style_src: @style_src,
        img_src: ~w('self' data:),
        font_src: ~w('self' data:),
        # TODO: Remove when https://bugs.webkit.org/show_bug.cgi?id=201591 is fixed
        connect_src: [ws_url | ~w('self')],
        media_src: ~w('none'),
        object_src: ~w('none'),
        prefetch_src: ~w('none'),
        child_src: ~w('none'),
        frame_src: ["https://player.vimeo.com" | @frame_src],
        worker_src: ~w('none'),
        frame_ancestors: ~w('none'),
        form_action: ~w('self'),
        block_all_mixed_content: ~w(),
        sandbox:
          ~w(allow-forms allow-scripts allow-modals allow-same-origin allow-downloads allow-popups),
        base_uri: ~w('none'),
        manifest_src: ~w('none')
      }

      directives =
        if Sentry.Config.environment_name() in Sentry.Config.included_environments() do
          dsn = URI.parse(Sentry.Config.dsn())

          [sentry_auth_user | _secret_key] =
            dsn
            |> Map.get(:userinfo)
            |> String.split(":", parts: 2)

          sentry_root =
            dsn
            |> Map.merge(%{
              userinfo: nil,
              path: nil
            })
            |> URI.to_string()

          sentry_csp_report_to =
            dsn
            |> Map.merge(%{
              userinfo: nil,
              path: "/api/2/security/?sentry_key=#{sentry_auth_user}"
            })
            |> URI.to_string()

          directives
          |> Map.put(:report_uri, System.get_env("SENTRY_CSP_REPORT_TO", sentry_csp_report_to))
          |> Map.update!(:script_src, &[sentry_root | &1])
          |> Map.update!(:connect_src, &[sentry_root | &1])
          |> Map.update!(:style_src, &["'#{System.get_env("SENTRY_STYLE_HASH")}'" | &1])
        else
          directives
        end

      directives =
        case home_url do
          %URI{scheme: "http"} -> directives
          %URI{scheme: "https"} -> Map.put(directives, :upgrade_insecure_requests, ~w())
        end

      [
        nonces_for: [:script_src, :style_src],
        directives: directives
      ]
    end

    plug HygeiaWeb.Plug.CheckAndRefreshAuthentication

    plug HygeiaWeb.Plug.SetupVersioning
  end

  pipeline :protected do
    plug HygeiaWeb.Plug.RequireAuthentication
  end

  pipeline :protected_webmaster do
    plug HygeiaWeb.Plug.HasRole, :webmaster
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser]

    live "/cases/:case_uuid/possible-index-submissions", PossibleIndexSubmissionLive.Index, :index

    live "/cases/:case_uuid/possible-index-submissions/new",
         PossibleIndexSubmissionLive.Create,
         :create

    live "/cases/:case_uuid/auto-tracing",
         AutoTracingLive.AutoTracing,
         :auto_tracing

    live "/cases/:case_uuid/auto-tracing/start",
         AutoTracingLive.Start,
         :start

    live "/cases/:case_uuid/auto-tracing/address",
         AutoTracingLive.Address,
         :address

    live "/cases/:case_uuid/auto-tracing/contact-methods",
         AutoTracingLive.ContactMethods,
         :contact_methods

    live "/cases/:case_uuid/auto-tracing/visits",
         AutoTracingLive.Visits,
         :visits

    live "/cases/:case_uuid/auto-tracing/employer",
         AutoTracingLive.Employer,
         :employer

    live "/cases/:case_uuid/auto-tracing/vaccination",
         AutoTracingLive.Vaccination,
         :vaccination

    live "/cases/:case_uuid/auto-tracing/covid-app",
         AutoTracingLive.CovidApp,
         :covid_app

    live "/cases/:case_uuid/auto-tracing/clinical",
         AutoTracingLive.Clinical,
         :clinical

    live "/cases/:case_uuid/auto-tracing/flights",
         AutoTracingLive.Flights,
         :flights

    live "/cases/:case_uuid/auto-tracing/transmission",
         AutoTracingLive.Transmission,
         :transmission

    live "/cases/:case_uuid/auto-tracing/contact-persons",
         AutoTracingLive.ContactPersons,
         :contact_persons

    live "/cases/:case_uuid/auto-tracing/end",
         AutoTracingLive.End,
         :end

    live "/cases/:case_uuid/auto-tracing/tenant-exit",
         AutoTracingLive.TenantExit,
         :tenant_exit

    live "/people/:person_uuid/overview", PersonOverviewLive.Index, :index

    live "/cases/:case_uuid/:phase_uuid/create-premature-release",
         PrematureReleaseLive.Create,
         :create
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser, :protected]

    live "/tenants/new", TenantLive.Create, :create
    live "/tenants/:id", TenantLive.Show, :show
    live "/tenants/:id/export", TenantLive.Export, :export
    get "/tenants/:id/export/:format", TenantController, :export
    live "/tenants/:id/edit", TenantLive.Show, :edit
    live "/tenants/:tenant_id/sedex-exports", SedexExportLive.Index, :index

    live "/tenants/:tenant_id/sedex-exports/:cursor_direction/:cursor",
         SedexExportLive.Index,
         :index

    live "/users", UserLive.Index, :index
    live "/users/:id", UserLive.Show, :show

    live "/people/:id/visits", VisitLive.Index, :show
    live "/people/:id/visits/new", VisitLive.Create, :create
    live "/people/visits/:visit_id", VisitLive.Show, :show
    live "/people/visits/:visit_id/edit", VisitLive.Show, :edit

    live "/people", PersonLive.Index, :index
    live "/people/new", PersonLive.Create, :create
    live "/people/:id", PersonLive.BaseData, :show
    live "/people/:id/edit", PersonLive.BaseData, :edit
    live "/people/:cursor_direction/:cursor", PersonLive.Index, :index

    live "/cases/:case_uuid/auto-tracing/resolve-problems",
         AutoTracingLive.ResolveProblems,
         :resolve_problems

    live "/cases/new", CaseLive.Create, :create
    live "/cases/new/possible-index/", CaseLive.CreatePossibleIndex, :create
    live "/cases/new/possible-index/:form_step", CaseLive.CreatePossibleIndex, :index
    live "/cases/new/possible-index/:form_step/new", CaseLive.CreatePossibleIndex, :new
    live "/cases/new/possible-index/:form_step/:index/edit", CaseLive.CreatePossibleIndex, :edit
    live "/cases/new/possible-index/:form_step/:index/show", CaseLive.CreatePossibleIndex, :show

    live "/cases/:id", CaseLive.BaseData, :show
    live "/cases/:id/edit", CaseLive.BaseData, :edit
    live "/cases/:id/transmissions", CaseLive.Transmissions, :show
    live "/cases/:id/tests", TestLive.Index, :show
    live "/cases/:id/tests/new", TestLive.Create, :create
    live "/cases/tests/:test_id", TestLive.Show, :show
    live "/cases/tests/:test_id/edit", TestLive.Show, :edit

    live "/transmissions/new", TransmissionLive.Create, :create
    live "/transmissions/:id", TransmissionLive.Show, :show
    live "/transmissions/:id/edit", TransmissionLive.Show, :edit

    live "/cases/:id/protocol", CaseLive.Protocol, :show
    live "/cases/:case_uuid/premature-releases", PrematureReleaseLive.Index, :index
    live "/cases/", CaseLive.Index, :index
    live "/cases/:cursor_direction/:cursor", CaseLive.Index, :index

    live "/organisations", OrganisationLive.Index, :index
    live "/organisations/merge", OrganisationLive.Merge, :merge
    live "/organisations/new", OrganisationLive.Create, :create
    live "/organisations/:id", OrganisationLive.Show, :show
    live "/organisations/:id/edit", OrganisationLive.Show, :edit

    live "/organisations/:organisation_id/divisions", DivisionLive.Index, :index
    live "/organisations/:organisation_id/divisions/merge", DivisionLive.Merge, :merge
    live "/organisations/:organisation_id/divisions/new", DivisionLive.Create, :create
    live "/divisions/:id", DivisionLive.Show, :show
    live "/divisions/:id/edit", DivisionLive.Show, :edit

    live "/organisations/:organisation_id/divisions/:cursor_direction/:cursor",
         DivisionLive.Index,
         :index

    live "/organisations/:organisation_id/affiliations", AffiliationLive.Index, :index

    live "/organisations/:organisation_id/affiliations/:cursor_direction/:cursor",
         AffiliationLive.Index,
         :index

    live "/organisations/:cursor_direction/:cursor", OrganisationLive.Index, :index

    live "/organisations/:id/positions/new", OrganisationLive.Show, :position_new

    live "/organisations/:id/positions/:position_id/edit",
         OrganisationLive.Show,
         :position_edit

    live "/history/:resource/:id", VersionLive.Show, :show

    live "/system_messages/new", SystemMessageLive.Create, :create
    live "/system_messages/:id", SystemMessageLive.Show, :show
    live "/system_messages/:id/edit", SystemMessageLive.Show, :edit

    live "/inbox/imports", ImportLive.Index, :index
    live "/inbox/imports/new", ImportLive.Create, :create
    live "/inbox/imports/:id", ImportLive.Show, :show

    live "/inbox/imports/:import_id/rows/apply-next-pending",
         RowLive.ApplyNextPending,
         :apply_next_pending

    live "/inbox/imports/:import_id/rows/:status", RowLive.Index, :index
    live "/inbox/imports/:import_id/rows/:status/:cursor_direction/:cursor", RowLive.Index, :index
    live "/inbox/rows/:id/apply", RowLive.Apply, :apply
    live "/inbox/rows/:id", RowLive.Show, :show

    live "/inbox/imports/:cursor_direction/:cursor", ImportLive.Index, :index

    live "/mutations", MutationLive.Index, :index
    live "/mutations/new", MutationLive.Create, :create

    live "/mutations/:id", MutationLive.Show, :show
    live "/mutations/:id/edit", MutationLive.Show, :edit
  end

  scope "/", HygeiaWeb do
    pipe_through [:browser]

    live "/", HomeLive.Index, :index

    live "/help", HelpLive.Index, :index

    live "/tenants", TenantLive.Index, :index

    live "/possible-index-submissions/:id",
         PossibleIndexSubmissionLive.Show,
         :show

    live "/possible-index-submissions/:id/edit",
         PossibleIndexSubmissionLive.Show,
         :edit

    live "/statistics", StatisticsLive.ChooseTenant, :index
    live "/statistics/:tenant_uuid/timeline/:from/:to", StatisticsLive.Timeline, :show
    live "/statistics/:tenant_uuid/timeline", StatisticsLive.Timeline, :show
    live "/statistics/:tenant_uuid/daily", StatisticsLive.DailyStatistics, :show
    live "/statistics/:tenant_uuid/daily/:date", StatisticsLive.DailyStatistics, :show
    live "/statistics/:tenant_uuid/export", StatisticsLive.Export, :show
    live "/statistics/:tenant_uuid/export/:from/:to", StatisticsLive.Export, :show
    live "/statistics/:tenant_uuid/last24hours", StatisticsLive.Last24HoursStatistics, :show
    get "/statistics/:tenant_uuid/export/:type/:from/:to", StatisticsController, :export

    live "/system_messages", SystemMessageLive.Index, :index

    get "/locale/:locale/:redirect_uri", LocaleController, :set_locale

    get "/pdf/isolation/:case_uuid/:phase_uuid", PdfController, :isolation_confirmation
    get "/pdf/quarantine/:case_uuid/:phase_uuid", PdfController, :quarantine_confirmation
    get "/pdf/isolation_end/:case_uuid/:phase_uuid", PdfController, :isolation_end_confirmation

    live "/auth/login", AuthLive.Login, :login
    get "/auth/:provider", AuthController, :request
    get "/auth/:provider/callback", AuthController, :callback
    post "/auth/:provider/callback", AuthController, :callback

    delete "/auth/", AuthController, :delete
    # This route also exists as get because of this issue
    # https://github.com/w3c/webappsec-csp/issues/8
    get "/auth/", AuthController, :delete
  end

  scope "/dashboard" do
    pipe_through [:browser, :protected, :protected_webmaster]

    live_dashboard "/",
      metrics: {HygeiaTelemetry, :dashboard_metrics},
      ecto_repos: [Hygeia.Repo],
      env_keys: [
        "WEB_PORT",
        "WEB_EXTERNAL_PORT",
        "WEB_EXTERNAL_HOST",
        "WEB_EXTERNAL_SCHEME",
        "IAM_ISSUER",
        "IAM_ORGANISATION_ID",
        "IAM_PROJECT_ID",
        "WEB_IAM_CLIENT_ID",
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

  forward(
    "/health",
    PlugCheckup,
    PlugCheckup.Options.new(
      json_encoder: Jason,
      checks: HygeiaHealth.checks(),
      timeout: :timer.seconds(15)
    )
  )
end
