FROM elixir:1.11-slim

# See https://github.com/wkhtmltopdf/wkhtmltopdf/issues/4497 about strip

RUN buildDeps='binutils' && \
  set -x && \
  apt-get update -qq && \
  apt-get install wkhtmltopdf $buildDeps -qq --no-install-recommends && \
  rm -rf /var/lib/apt/lists/* && \
  strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so* && \
  apt-get purge -qq --auto-remove $buildDeps

ADD _build/prod/rel/hygeia /app
ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["start"]