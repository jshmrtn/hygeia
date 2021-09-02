#!/bin/bash

eval "$(gp env -e)"

# add env deps
asdf install

# init db
docker volume create postgres
docker run \
    --restart always \
    --name postgres \
    -v postgres:/var/lib/postgresql/data \
    -p 5432:5432 \
    -d \
    -e POSTGRES_PASSWORD="" \
    -e POSTGRES_USER="root" \
    -e POSTGRES_HOST_AUTH_METHOD="trust" \
    postgres:latest

# install frontend deps
cd apps/hygeia_web/assets || exit
npm install
cd ../../.. || exit

# install .env
cp .env.example .env

# install elixir deps
mix local.hex --force
mix local.rebar --force

# install deps
mix deps.clean --all
mix deps.get
mix deps.compile

# init schema
cd apps/hygeia || exit
mix ecto.setup
cd ../.. || exit

# compile
mix compile