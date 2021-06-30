# Hygeia

[![.github/workflows/ci.yml](https://github.com/jshmrtn/hygeia/actions/workflows/ci.yml/badge.svg)](https://github.com/jshmrtn/hygeia/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/jshmrtn/hygeia/badge.svg?branch=master)](https://coveralls.io/github/jshmrtn/hygeia?branch=master)
[![License](https://img.shields.io/badge/License-BSL%201.1%20%2F%20Apache%202.0-blue.svg)](https://mariadb.com/bsl11/)
[![Last Updated](https://img.shields.io/github/last-commit/jshmrtn/hygeia.svg)](https://github.com/jshmrtn/hygeia/commits/master)

## Development

To start your Phoenix server:

- [Install `wkhtmltopdf`](https://github.com/gutschilla/elixir-pdf-generator#wkhtmltopdf)
- Install `poppler-utils` (`brew install poppler`, `apt-get install poppler-utils`, `apk add poppler-utils`)
- Install Elixir / Node / Erlang using [`asdf`](https://asdf-vm.com/) as specified in `.tool-versions`
- Start Database

```console
$ docker volume create postgres
$ docker run \
    --restart always \
    --name postgres \
    -v postgres:/var/lib/postgresql/data \
    -p 5432:5432 \
    -d \
    -e POSTGRES_PASSWORD="" \
    -e POSTGRES_USER="root" \
    -e POSTGRES_HOST_AUTH_METHOD="trust" \
    postgres:latest
```

- Install dependencies with `mix deps.get`
- Create Local `.env` file
- Load Local `.env` file
  - For `zsh` users I recommend https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dotenv
  - Using `` npx dotenv-cli `ps -o fname --no-headers $$ `` you can load all env variables into a new shell instead
- Create and migrate your database with `mix ecto.setup` inside the `apps/hygeia` directory
- Install Node.js dependencies with `npm install` inside the `apps/hygeia_web/assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Translation

Extract all translation strings to create `*.pot`-files:

```console
mix gettext.extract.umbrella
```

Then merge those into the localized `*.po`-files:

```console
cd apps/hygeia_gettext
mix gettext.merge priv/gettext --locale=de &  mix gettext.merge priv/gettext --locale=en
```

You can now edit the translations using [Poedit](https://poedit.net/) or similar software.

### Formatting

Run `mix surface.format` to format all `*.sface` template files.

## Environment Variables

See [`.env.example`](./.env.example)

## Talks

### [Code BEAM V Europe 2021](https://codesync.global/speaker/jonatan-maennchen/#845covid-19-contact-tracing-on-the-beam)

[![COVID-19 contact tracing on the BEAM - Jonatan Männchen; Jeremy "Jay" Zahner | Code BEAM V Europe](https://img.youtube.com/vi/nbrQKSrUfvQ/0.jpg)](https://www.youtube.com/watch?v=nbrQKSrUfvQ)
