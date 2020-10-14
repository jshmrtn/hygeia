# Hygeia

## Development

To start your Phoenix server:

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
  * `POOL_SIZE` (default `10`) - Database Pool Size
* Clustering
  * `RELEASE_NAME` (`optional`) - App Name
  * `KUBERNETES_POD_SELECTOR` (`optional`) - Selector to load Pod List
  * `KUBERNETES_NAMESPACE` (`optional`) - Kubernetes Namespace
* Security
  * `SECRET_KEY_BASE` (`required`) - Secret Key to generate Tokens with