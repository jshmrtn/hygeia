defmodule HygeiaApi.GraphQLCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require GraphQL.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  # use Absinthe.Phoenix.SubscriptionTest, schema: HygeiaApi.Schema

  # import Phoenix.ChannelTest

  alias HygeiaApi.Endpoint
  alias HygeiaApi.Schema

  # @endpoint Endpoint

  using do
    quote do
      import unquote(__MODULE__)

      use Absinthe.Phoenix.SubscriptionTest, schema: HygeiaApi.Schema
    end
  end

  @spec run(
          input :: String.t() | Absinthe.Language.Source.t() | Absinthe.Language.Document.t(),
          options :: Absinthe.run_opts()
        ) :: Absinthe.run_result()
  def run(input, options \\ []) do
    options = options |> Keyword.put_new(:context, %{}) |> put_in([:context, :pubsub], Endpoint)
    Absinthe.run(input, Schema, options)
  end

  @spec run!(
          input :: String.t() | Absinthe.Language.Source.t() | Absinthe.Language.Document.t(),
          options :: Absinthe.run_opts()
        ) :: Absinthe.result_t()
  def run!(input, options \\ []) do
    options = options |> Keyword.put_new(:context, %{}) |> put_in([:context, :pubsub], Endpoint)
    Absinthe.run!(input, Schema, options)
  end

  defmacro assert_no_error(result) do
    quote location: :keep do
      refute Map.has_key?(unquote(result), :errors)
    end
  end

  @spec global_id(node_type :: String.t(), source_id :: String.t()) :: String.t()
  def global_id(node_type, source_id),
    do: Absinthe.Relay.Node.to_global_id(node_type, source_id, Schema)
end
