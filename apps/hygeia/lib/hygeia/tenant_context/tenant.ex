defmodule Hygeia.TenantContext.Tenant do
  @moduledoc """
  Model for Tenants
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.TenantContext.SedexExport
  alias Hygeia.TenantContext.Tenant.SedexExportConfiguration
  alias Hygeia.TenantContext.Tenant.Smtp
  alias Hygeia.TenantContext.Tenant.TemplateParameters
  alias Hygeia.TenantContext.Tenant.Websms

  defenum TemplateVariation, :template_variation, [:sg, :ar, :ai]

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: String.t() | nil,
          name: String.t() | nil,
          case_management_enabled: boolean | nil,
          public_statistics: boolean | nil,
          outgoing_mail_configuration: Smtp.t() | nil,
          outgoing_sms_configuration: Websms.t() | nil,
          people: Ecto.Schema.has_many(Person.t()) | nil,
          cases: Ecto.Schema.has_many(Case.t()) | nil,
          sedex_exports: Ecto.Schema.has_many(SedexExport.t()) | nil,
          override_url: String.t() | nil,
          template_variation: TemplateVariation.t() | nil,
          iam_domain: String.t() | nil,
          from_email: String.t() | nil,
          short_name: String.t() | nil,
          template_parameters: TemplateParameters.t() | nil,
          sedex_export_enabled: boolean() | nil,
          sedex_export_configuration: SedexExportConfiguration.t() | nil,
          related_system_messages: Ecto.Schema.many_to_many(SystemMessage.t()) | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          case_management_enabled: boolean,
          public_statistics: boolean,
          outgoing_mail_configuration: Smtp.t() | nil,
          outgoing_sms_configuration: Websms.t() | nil,
          people: Ecto.Schema.has_many(Person.t()),
          cases: Ecto.Schema.has_many(Case.t()),
          sedex_exports: Ecto.Schema.has_many(SedexExport.t()),
          override_url: String.t() | nil,
          template_variation: TemplateVariation.t() | nil,
          iam_domain: String.t() | nil,
          from_email: String.t() | nil,
          short_name: String.t() | nil,
          template_parameters: TemplateParameters.t() | nil,
          sedex_export_enabled: boolean(),
          sedex_export_configuration: SedexExportConfiguration.t() | nil,
          related_system_messages: Ecto.Schema.many_to_many(SystemMessage.t()),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "tenants" do
    field :name, :string
    field :case_management_enabled, :boolean, default: false
    field :public_statistics, :boolean, default: false
    field :override_url, :string
    field :template_variation, TemplateVariation
    field :iam_domain, :string
    field :short_name, :string
    field :from_email, :string
    field :sedex_export_enabled, :boolean, default: false

    has_many :people, Person
    has_many :cases, Case
    has_many :sedex_exports, SedexExport

    many_to_many :related_system_messages, SystemMessage,
      join_through: "system_message_tenants",
      join_keys: [tenant_uuid: :uuid, system_message_uuid: :uuid]

    timestamps()

    field :outgoing_mail_configuration, PolymorphicEmbed,
      types: [
        smtp: Smtp
      ],
      on_replace: :update

    field :outgoing_sms_configuration, PolymorphicEmbed,
      types: [
        websms: Websms
      ],
      on_replace: :update

    embeds_one :sedex_export_configuration, SedexExportConfiguration, on_replace: :update
    embeds_one :template_parameters, TemplateParameters, on_replace: :update

    # Use in Protocol Creation Form
    field :outgoing_mail_configuration_type, :string, virtual: true, default: "smtp"
    field :outgoing_sms_configuration_type, :string, virtual: true
  end

  @spec changeset(tenant :: t | empty, attrs :: Hygeia.ecto_changeset_params()) :: Changeset.t()
  def changeset(tenant, attrs) do
    # Mapping "" to nil because of overridden empty_values
    attrs =
      case attrs do
        %{template_variation: ""} -> Map.put(attrs, :template_variation, nil)
        %{"template_variation" => ""} -> Map.put(attrs, "template_variation", nil)
        _other -> attrs
      end

    tenant
    |> cast(attrs, [
      :name,
      :case_management_enabled,
      :public_statistics,
      :outgoing_mail_configuration_type,
      :outgoing_sms_configuration_type,
      :override_url,
      :template_variation,
      :iam_domain,
      :short_name,
      :from_email,
      :sedex_export_enabled
    ])
    |> validate_required([:name, :public_statistics, :case_management_enabled])
    |> cast_polymorphic_embed(:outgoing_mail_configuration)
    |> cast_polymorphic_embed(:outgoing_sms_configuration)
    |> cast_embed(:template_parameters)
    |> maybe_cast_embed(:sedex_export_configuration, :sedex_export_enabled)
    |> validate_url(:override_url)
    |> foreign_key_constraint(:people,
      name: :cases_tenant_uuid_fkey,
      message: "has assigned relations"
    )
    |> foreign_key_constraint(:cases,
      name: :people_tenant_uuid_fkey,
      message: "has assigned relations"
    )
    |> unique_constraint(:iam_domain)
    |> unique_constraint(:short_name)
  end

  defp maybe_cast_embed(changeset, embed, enable) do
    if Changeset.fetch_field!(changeset, enable) == true do
      cast_embed(changeset, embed)
    else
      put_embed(changeset, embed, nil)
    end
  end

  @spec validate_url(changeset :: Changeset.t(), field :: atom, opts :: [atom]) :: Changeset.t()
  def validate_url(changeset, field, opts \\ []) do
    validate_change(changeset, field, fn
      ^field, value when value in ["", nil] ->
        []

      ^field, value ->
        value
        |> URI.parse()
        |> case do
          %URI{scheme: nil} ->
            "is missing a scheme (e.g. https)"

          %URI{host: nil} ->
            "is missing a host"

          %URI{host: host} ->
            case :inet.gethostbyname(Kernel.to_charlist(host)) do
              {:ok, _host_entry} -> :ok
              {:error, _reason} -> "invalid host"
            end
        end
        |> case do
          error when is_binary(error) -> [{field, Keyword.get(opts, :message, error)}]
          :ok -> []
        end
    end)
  end

  @spec get_message_signature_text(tenant :: t, message_type :: atom) :: String.t()
  def get_message_signature_text(
        %{template_parameters: %{sms_signature: sms_signature}},
        :sms
      ),
      do: sms_signature

  def get_message_signature_text(
        %{template_parameters: %{email_signature: email_signature}},
        :email
      ),
      do: email_signature

  def get_message_signature_text(_tenant, _message_type), do: ""

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Tenant.t()) :: Tenant.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Tenant.t(),
            action :: :create | :details | :list | :update | :delete | :export_data,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_tenant, :list, _user, _meta), do: true

    def authorized?(%Tenant{public_statistics: true} = _tenant, :statistics, _user, _meta),
      do: true

    def authorized?(_tenant, action, :anonymous, _meta)
        when action in [
               :create,
               :details,
               :update,
               :delete,
               :statistics,
               :versioning,
               :deleted_versioning
             ],
        do: false

    def authorized?(tenant, :statistics, user, _meta),
      do:
        Enum.any?(
          [:statistics_viewer, :viewer, :tracer, :super_user, :supervisor, :admin],
          &User.has_role?(user, &1, tenant)
        )

    def authorized?(tenant, action, user, _meta)
        when action in [:details, :update, :delete, :versioning, :deleted_versioning],
        do: User.has_role?(user, :admin, tenant) or User.has_role?(user, :webmaster, :any)

    def authorized?(tenant, :export_data, user, _meta),
      do: User.has_role?(user, :admin, tenant) or User.has_role?(user, :data_exporter, :any)

    def authorized?(_tenant, :create, user, _meta),
      do: User.has_role?(user, :webmaster, :any)
  end
end
