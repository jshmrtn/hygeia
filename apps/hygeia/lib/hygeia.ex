defmodule Hygeia do
  @moduledoc """
  Hygeia keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  Also the entrypoint for defining your models etc.

  This can be used in your application as:

      use Hygeia, :model
      use Hygeia, :migration

  The definitions below will be executed for every model, migration, etc,
  so keep them short and clean, focused on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  @type ecto_changeset_params :: %{required(binary()) => term()} | %{required(atom()) => term()}

  def model do
    quote do
      use Ecto.Schema
      use I18nHelpers.Ecto.TranslatableFields

      import Ecto.Changeset

      alias Money.Ecto.Composite.Type, as: MoneyType

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts type: :naive_datetime_usec
    end
  end

  def migration do
    quote do
      use Ecto.Migration

      import Ecto.Query
    end
  end

  def context do
    quote do
      import Ecto.Query, warn: false
      import MHygeia.Helpers.PostgresError

      alias Hygeia.Repo
    end
  end
end
