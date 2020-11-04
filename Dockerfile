FROM elixir:1.11-slim

RUN apt-get update && \
  apt-get install wkhtmltopdf -y && \
  rm -rf /var/lib/apt/lists/*

ADD _build/prod/rel/hygeia /app
ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["start"]