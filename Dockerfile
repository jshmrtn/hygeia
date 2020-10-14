FROM hexpm/elixir:1.11.0-erlang-23.1.1-alpine-3.12.0

ADD _build/prod/rel/hygeia /app
ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["start"]