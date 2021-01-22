defmodule Sedex.Storage.Minio do
  @moduledoc """
  Minio Adapter for Sedex
  """

  @behaviour Sedex.Storage

  alias ExAws.S3

  # 5 MB
  @chunk_size 5 * 1024 * 1024

  @impl Sedex.Storage
  def store(filename, directory, content) do
    {:ok, content_file} = StringIO.open(content)

    %{status_code: 200} =
      content_file
      |> IO.binstream(@chunk_size)
      |> S3.upload(directory, filename)
      |> ExAws.request!(aws_config())

    :ok
  end

  @impl Sedex.Storage
  def read(filename, directory) do
    {:ok,
     directory
     |> ExAws.S3.download_file(filename, :memory)
     |> ExAws.stream!(aws_config())
     |> Enum.to_list()
     |> IO.iodata_to_binary()}
  rescue
    exception in ExAws.Error ->
      if exception.message =~ "404" do
        {:error, :not_found}
      else
        reraise exception, __STACKTRACE__
      end
  end

  @impl Sedex.Storage
  def cleanup(directory, id) do
    directory
    |> ExAws.S3.list_objects()
    |> ExAws.stream!(aws_config())
    |> Stream.filter(&String.contains?(&1.key, id))
    |> Task.async_stream(
      &(directory
        |> ExAws.S3.delete_object(&1.key)
        |> ExAws.request!(aws_config()))
    )
    |> Stream.run()
  end

  defp aws_config, do: Application.fetch_env!(:sedex, __MODULE__)
end
