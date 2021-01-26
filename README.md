# Hygeia

## Development

To start your Phoenix server:

* [Install `wkhtmltopdf`](https://github.com/gutschilla/elixir-pdf-generator#wkhtmltopdf)
* Install `poppler-utils` (`brew install poppler`, `apt-get install poppler-utils`, `apk add poppler-utils`)
* Start Database

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

```console
$ docker volume create sedex
$ docker run \
    --restart always \
    --name minio-sedex \
    -v sedex:/sedex-data \
    -p 9000:9000 \
    -d \
    -e MINIO_ROOT_USER="root" \
    -e MINIO_ROOT_PASSWORD="rootroot" \
    --entrypoint=sh \
    minio/minio:RELEASE.2021-01-16T02-19-44Z \
    -c " \
    ls -al / && \
    mkdir -p /sedex-data/interface/inbox && \
    mkdir -p /sedex-data/interface/outbox && \
    mkdir -p /sedex-data/interface/processed && \
    mkdir -p /sedex-data/interface/receipts && \
    mkdir -p /sedex-data/interface/working && \
    /usr/bin/docker-entrypoint.sh minio server /sedex-data/interface"
```

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup` inside the `apps/hygeia` directory
  * Install Node.js dependencies with `npm install` inside the `apps/hygeia_web/assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Environment Variables

* Web
  * `WEB_PORT` (default `4000`) - Port of the Web Server
  * `WEB_EXTERNAL_PORT` (default same as port) - Externally Reachable Port
  * `WEB_EXTERNAL_HOST` (default `localhost`) - Externally Reachable Host
  * `WEB_EXTERNAL_SCHEME` (default `http`) - Externally Reachable Scheme (http/https)
  * `WEB_IAM_ISSUER` (default `https://issuer.zitadel.ch`) - IAM Issuer
  * `WEB_IAM_CLIENT_ID` (default `***REMOVED***`) - IAM Client ID
  * `WEB_IAM_CLIENT_SECRET` (default `***REMOVED***`) - IAM Client Secret
* API Web Server
  * `API_PORT` (default `4001`) - Port of the Web Server
  * `API_EXTERNAL_PORT` (default same as port) - Externally Reachable Port
  * `API_EXTERNAL_HOST` (default `localhost`) - Externally Reachable Host
  * `API_EXTERNAL_SCHEME` (default `http`) - Externally Reachable Scheme (http/https)
* Database (Postgres)
  * `DATABASE_SSL` (default `false`) - Use SSL for Database
  * `DATABASE_USER` (default `root`) - Database Username
  * `DATABASE_PASSWORD` (default empty`) - Database User Password
  * `DATABASE_NAME` (default `hygeia`) - Database Name
  * `DATABASE_PORT` (default `5432`) - Database Port
  * `DATABASE_HOST` (default `localhost`) - Database Hostname / IP
  * `DATABASE_POOL_SIZE` (default `10`) - Database Pool Size
* Clustering
  * `RELEASE_NAME` (`optional`) - App Name
  * `KUBERNETES_POD_SELECTOR` (`optional`) - Selector to load Pod List
  * `KUBERNETES_NAMESPACE` (`optional`) - Kubernetes Namespace
* Security
  * `SECRET_KEY_BASE` (`required`) - Secret Key to generate Tokens with
* Prometheus Metrics
  * `METRICS_PORT` (default `9568`) - Prometheus Metrics Port
* IAM
  * `IAM_ORGANISATION_ID` (default `***REMOVED***`) - IAM Organisation to sync users from
  * `IAM_PROJECT_ID` (default `***REMOVED***`) - IAM Project to sync users from
  * `IAM_SERVICE_ACCOUNT_USER_SYNC_LOGIN` (default: json) - IAM Login for User Sync
* Email
  * `DKIM_PATH` (default `apps/hygeia/priv/test/dkim`) - Base Path for DKIM Certificates
* Sedex
  * `SEDEX_FILESYSTEM_ADAPTER` (default `filesystem`) - Filesystem Adapter for the resulting files
    * `filesystem` - Store on local Filesystem
    * `minio` - Store via Minio
  * `SEDEX_FILESYSTEM_MINIO_USER` (default `root`) - Minio Username
  * `SEDEX_FILESYSTEM_MINIO_PASSWORD` (default `rootroot`) - Minio Password
  * `SEDEX_FILESYSTEM_MINIO_SCHEME` (default `http`) - Mini Access Scheme
  * `SEDEX_FILESYSTEM_MINIO_PORT` (default `9000`) - Minio Port
  * `SEDEX_FILESYSTEM_MINIO_HOST` (default `localhost`) - Minio Host