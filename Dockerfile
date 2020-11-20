FROM elixir:1.11-slim

# See https://github.com/wkhtmltopdf/wkhtmltopdf/issues/4497 about strip

RUN buildDeps='binutils curl' && \
  set -x && \
  apt-get update -qq && \
  apt-get install $buildDeps -qq && \
  curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb -o wkhtmltopdf.deb && \
  apt-get install -qq ./wkhtmltopdf.deb && \
  rm ./wkhtmltopdf.deb && \
  rm -rf /var/lib/apt/lists/* && \
  apt-get purge -qq --auto-remove $buildDeps

ADD _build/prod/rel/hygeia /app
ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["start"]