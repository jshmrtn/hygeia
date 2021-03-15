[
  import_deps: [:ecto, :ecto_enum],
  inputs: [
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "priv/repo/seeds/*.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
