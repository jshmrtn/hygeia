defmodule Sedex.Storage do
  @moduledoc """
  Sedex Storage Interface
  """

  @type t :: Sedex.Storage.Filesystem | Sedex.Storage.Minio

  @callback store(filename :: Path.t(), directory :: Path.t(), content :: binary()) :: :ok

  @callback read(filename :: Path.t(), directory :: Path.t()) ::
              {:ok, content :: binary()} | {:error, :not_found}

  @callback cleanup(directory :: Path.t(), id :: String.t()) :: :ok
end
