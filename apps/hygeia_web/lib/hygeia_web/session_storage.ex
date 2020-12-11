defmodule HygeiaWeb.SessionStorage do
  @moduledoc false

  @behaviour Plug.Session.Store

  defmodule Storage do
    @moduledoc false

    use Nebulex.Cache,
      otp_app: :hygeia_web,
      adapter: Nebulex.Adapters.Replicated

    defmodule Primary do
      @moduledoc false

      use Nebulex.Cache,
        otp_app: :hygeia_web,
        adapter: Nebulex.Adapters.Local
    end
  end

  @impl Plug.Session.Store
  def init(opts), do: Keyword.put_new(opts, :ttl, 3_600)

  @impl Plug.Session.Store
  def put(conn, nil, data, opts), do: put(conn, Ecto.UUID.generate(), data, opts)

  def put(_conn, sid, data, opts) do
    Storage.set(sid, data, ttl: Keyword.fetch!(opts, :ttl), on_conflict: :override)

    sid
  end

  @impl Plug.Session.Store
  def get(_conn, cookie, _opts) do
    cookie
    |> Storage.get()
    |> case do
      nil -> {nil, %{}}
      %{} = data -> {cookie, data}
    end
  end

  @impl Plug.Session.Store
  def delete(_conn, sid, _opts) do
    Storage.delete(sid)
    :ok
  end
end
