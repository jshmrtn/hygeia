#!/bin/bash

eval "$(gp env -e)"

docker start postgres;

cd apps/hygeia || exit
mix ecto.migrate
cd ../../ || exit
mix deps.get
iex -S mix phx.server