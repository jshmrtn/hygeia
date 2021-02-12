defmodule SentryEventFilter do
  @moduledoc """
  Sentry Event Filter for Plug
  """

  @behaviour Sentry.EventFilter

  @impl Sentry.EventFilter
  def exclude_exception?(exception, _source), do: Plug.Exception.status(exception) < 500
end
