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

  @type paginator_page(row_type) :: %Paginator.Page{
          entries: [row_type],
          metadata: Paginator.Page.Metadata.t()
        }

  @type validity_timeframe :: {amount :: pos_integer(), unit :: atom()}

  @doc false
  @spec model :: Macro.t()
  def model do
    quote location: :keep do
      use Ecto.Schema

      import Ecto.Changeset

      import Hygeia.Helpers.Calendar
      import Hygeia.Helpers.Country
      import Hygeia.Helpers.DNS
      import Hygeia.Helpers.Email
      import Hygeia.Helpers.Empty
      import Hygeia.Helpers.Id
      import Hygeia.Helpers.Merge
      import Hygeia.Helpers.PersonDuplicates
      import Hygeia.Helpers.Phone

      import PolymorphicEmbed,
        only: [cast_polymorphic_embed: 2, polymorphic_embeds_one: 2, polymorphic_embeds_many: 2]

      alias Ecto.Changeset

      @primary_key {:uuid, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts type: :utc_datetime_usec
    end
  end

  @doc false
  @spec migration :: Macro.t()
  def migration do
    quote location: :keep do
      use Ecto.Migration

      import Ecto.Query
      import Hygeia.Helpers.Versioning

      defp noop, do: :ok
    end
  end

  @doc false
  @spec context :: Macro.t()
  def context do
    quote location: :keep do
      import Ecto.Query, warn: false
      import Hygeia.Helpers.PostgresError
      import Hygeia.Helpers.PubSub
      import Hygeia.Helpers.Versioning

      alias Hygeia.Repo

      alias Ecto.Changeset
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
