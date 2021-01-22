defmodule Sedex.Storage.Filesystem do
  @moduledoc """
  Filesystem Adapter for Sedex
  """

  @behaviour Sedex.Storage

  @impl Sedex.Storage
  def store(filename, directory, content) do
    path = Path.join([base_path(), directory, filename])

    File.mkdir_p!(Path.dirname(path))

    File.write!(path, content)

    :ok
  end

  @impl Sedex.Storage
  def read(filename, directory) do
    [base_path(), directory, filename]
    |> Path.join()
    |> File.read()
    |> case do
      {:ok, content} -> {:ok, content}
      {:error, :enoent} -> {:error, :not_found}
    end
  end

  @impl Sedex.Storage
  def cleanup(directory, id) do
    base_path()
    |> Path.join(directory)
    |> Kernel.<>("/*#{id}*")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      File.rm!(path)
    end)

    :ok
  end

  @spec base_path :: Path.t()
  def base_path, do: Application.app_dir(:sedex, "priv/test/sedex")
end
