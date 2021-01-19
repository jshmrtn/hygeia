defmodule Sedex.Storage do
  @moduledoc """
  Sedex Storage Interface
  """

  @type t :: Sedex.Storage.Filesystem | Sedex.Storage.Minio

  @callback store(directory :: Path.t(), filename :: Path.t(), content :: binary()) :: :ok
end
