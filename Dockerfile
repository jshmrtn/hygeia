ARG ELIXIR_VERSION=1.13.0
ARG ERLANG_VERSION=24.1.6
ARG HEXPM_BOB_OS=debian
ARG HEXPM_BOB_OS_VERSION=bullseye-20210902-slim

FROM hexpm/elixir:$ELIXIR_VERSION-erlang-$ERLANG_VERSION-$HEXPM_BOB_OS-$HEXPM_BOB_OS_VERSION

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
    apt-get install -qq software-properties-common && \
    rm -rf /var/lib/apt/lists/*

RUN buildDeps='binutils curl' && \
  set -x && \
  add-apt-repository "deb http://http.us.debian.org/debian $(lsb_release -sc) contrib" && \
  (echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections) && \
  apt-get update -qq && \
  apt-get install -qq $buildDeps wget xorg xz-utils fontconfig libxrender1 libxext6 libx11-6 openssl xfonts-base ttf-mscorefonts-installer xfonts-75dpi && \
  curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb -o wkhtmltopdf.deb && \
  apt-get install -qq ./wkhtmltopdf.deb && \
  rm ./wkhtmltopdf.deb && \
  rm -rf /var/lib/apt/lists/* && \
  apt-get purge -qq --auto-remove $buildDeps

ADD _build/prod/rel/hygeia /app
ADD entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["start"]