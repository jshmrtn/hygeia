defmodule HygeiaApi.Router do
  use HygeiaApi, :router

  alias HygeiaApi.Schema
  alias HygeiaApi.UserSocket

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: Schema,
    socket: UserSocket,
    interface: :playground

  forward "/", Absinthe.Plug, schema: Schema, socket: UserSocket
end
