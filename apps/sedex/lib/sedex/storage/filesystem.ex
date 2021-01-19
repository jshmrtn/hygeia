defmodule Sedex.Storage.Filesystem do
  @moduledoc """
  Filesystem Adapter for Sedex
  """

  @behaviour Sedex.Storage

  @impl Sedex.Storage
  def store(directory, filename, content) do
    path = Path.join([base_path(), directory, filename])

    File.mkdir_p!(Path.dirname(path))

    File.write!(path, content)

    :ok
  end

  @spec base_path :: Path.t()
  def base_path, do: Application.app_dir(:sedex, "priv/test/sedex")
end
