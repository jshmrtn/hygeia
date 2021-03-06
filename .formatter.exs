[
  import_deps: [:phoenix, :phoenix_live_view, :surface, :ecto, :ecto_enum],
  inputs: [
    ".dialyzer_ignore.exs",
    ".formatter.exs",
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "priv/repo/seeds/*.exs",
    "{config,lib,test}/**/*.{ex,exs,sface,heex}"
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Surface.Formatter.Plugin, Cldr.Formatter.Plugin, Phoenix.LiveView.HTMLFormatter]
]
