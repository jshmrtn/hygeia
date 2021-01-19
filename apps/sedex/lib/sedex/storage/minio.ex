defmodule Sedex.Storage.Minio do
  @moduledoc """
  Minio Adapter for Sedex
  """

  @behaviour Sedex.Storage

  alias ExAws.S3

  # 5 MB
  @chunk_size 5 * 1024 * 1024

  @impl Sedex.Storage
  def store(directory, filename, content) do
    {:ok, content_file} = StringIO.open(content)

    %{status_code: 200} =
      content_file
      |> IO.binstream(@chunk_size)
      |> S3.upload(directory, filename)
      |> ExAws.request!(aws_config())

    :ok
  end

  defp aws_config, do: Application.fetch_env!(:sedex, __MODULE__)
end
