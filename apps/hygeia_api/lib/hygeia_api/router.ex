defmodule HygeiaApi.Router do
  use HygeiaApi, :router

  alias HygeiaApi.Schema
  alias HygeiaApi.UserSocket

  forward(
    "/health",
    PlugCheckup,
    PlugCheckup.Options.new(
      json_encoder: Jason,
      checks: HygeiaHealth.checks(),
      timeout: :timer.seconds(15)
    )
  )

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: Schema,
    socket: UserSocket,
    interface: :playground

  forward "/", Absinthe.Plug, schema: Schema, socket: UserSocket
end
