defmodule Hygeia.TenantContext.Tenant do
  @moduledoc """
  Model for Tenants
  """

  use Hygeia, :model

  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.EctoType.Country
  alias Hygeia.ImportContext.Import
  alias Hygeia.SystemMessageContext.SystemMessage
  alias Hygeia.TenantContext.SedexExport
  alias Hygeia.TenantContext.Tenant.SedexExportConfiguration
  alias Hygeia.TenantContext.Tenant.Smtp
  alias Hygeia.TenantContext.Tenant.TemplateParameters
  alias Hygeia.TenantContext.Tenant.Websms

  @derive {Phoenix.Param, key: :uuid}

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          case_management_enabled: boolean | nil,
          public_statistics: boolean | nil,
          outgoing_mail_configuration: Smtp.t() | nil,
          outgoing_sms_configuration: Websms.t() | nil,
          people: Ecto.Schema.has_many(Person.t()) | nil,
          cases: Ecto.Schema.has_many(Case.t()) | nil,
          imports: Ecto.Schema.has_many(Import.t()) | nil,
          sedex_exports: Ecto.Schema.has_many(SedexExport.t()) | nil,
          override_url: String.t() | nil,
          template_variation: String.t() | nil,
          iam_domain: String.t() | nil,
          from_email: String.t() | nil,
          template_parameters: TemplateParameters.t() | nil,
          sedex_export_enabled: boolean() | nil,
          sedex_export_configuration: SedexExportConfiguration.t() | nil,
          related_system_messages: Ecto.Schema.many_to_many(SystemMessage.t()) | nil,
          subdivision: String.t() | nil,
          country: Country.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          name: String.t(),
          case_management_enabled: boolean,
          public_statistics: boolean,
          outgoing_mail_configuration: Smtp.t() | nil,
          outgoing_sms_configuration: Websms.t() | nil,
          people: Ecto.Schema.has_many(Person.t()),
          cases: Ecto.Schema.has_many(Case.t()),
          imports: Ecto.Schema.has_many(Import.t()),
          sedex_exports: Ecto.Schema.has_many(SedexExport.t()),
          override_url: String.t() | nil,
          template_variation: String.t() | nil,
          iam_domain: String.t() | nil,
          from_email: String.t() | nil,
          template_parameters: TemplateParameters.t() | nil,
          sedex_export_enabled: boolean(),
          sedex_export_configuration: SedexExportConfiguration.t() | nil,
          related_system_messages: Ecto.Schema.many_to_many(SystemMessage.t()),
          subdivision: String.t() | nil,
          country: Country.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "tenants" do
    field :name, :string
    field :case_management_enabled, :boolean, default: false
    field :public_statistics, :boolean, default: false
    field :override_url, :string
    field :template_variation, :string
    field :iam_domain, :string
    field :from_email, :string
    field :sedex_export_enabled, :boolean, default: false
    field :subdivision, :string
    field :country, Country

    has_many :people, Person
    has_many :cases, Case
    has_many :sedex_exports, SedexExport
    has_many :imports, Import

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
      :from_email,
      :sedex_export_enabled,
      :subdivision,
      :country
    ])
    |> validate_required([:name, :public_statistics, :case_management_enabled])
    |> validate_subdivision(:subdivision, :country)
    |> cast_polymorphic_embed(:outgoing_mail_configuration)
    |> cast_polymorphic_embed(:outgoing_sms_configuration)
    |> cast_embed(:template_parameters)
    |> maybe_cast_embed(:sedex_export_configuration, :sedex_export_enabled)
    |> validate_url(:override_url)
    |> clear_fields_when_management_disabled()
    |> clear_fields_when_no_iam_disabled()
    |> foreign_key_constraint(:people,
      name: :cases_tenant_uuid_fkey,
      message: "has assigned relations"
    )
    |> foreign_key_constraint(:cases,
      name: :people_tenant_uuid_fkey,
      message: "has assigned relations"
    )
    |> unique_constraint(:iam_domain)
    |> unique_constraint(:subdivision)
  end

  defp maybe_cast_embed(changeset, embed, enable) do
    if Changeset.fetch_field!(changeset, enable) == true do
      cast_embed(changeset, embed)
    else
      put_embed(changeset, embed, nil)
    end
  end

  defp clear_fields_when_management_disabled(changeset) do
    if fetch_field!(changeset, :case_management_enabled) do
      changeset
    else
      changeset
      |> change(%{
        public_statistics: false,
        override_url: nil,
        subdivision: nil,
        country: nil,
        outgoing_sms_configuration: nil,
        template_variation: nil,
        sedex_export_enabled: false
      })
      |> put_embed(:template_parameters, nil)
    end
  end

  defp clear_fields_when_no_iam_disabled(changeset) do
    if fetch_field!(changeset, :iam_domain) in ["", nil] do
      changeset
      |> change(%{
        public_statistics: false,
        override_url: nil,
        outgoing_mail_configuration: nil,
        outgoing_sms_configuration: nil,
        template_variation: nil,
        sedex_export_enabled: false,
        from_email: nil
      })
      |> put_embed(:template_parameters, nil)
    else
      changeset
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

  @spec get_message_signature_text(tenant :: t, message_type :: :sms | :email) :: String.t()
  def get_message_signature_text(tenant, message_type)

  def get_message_signature_text(
        %__MODULE__{template_parameters: %TemplateParameters{sms_signature: sms_signature}},
        :sms
      ),
      do: sms_signature

  def get_message_signature_text(
        %__MODULE__{template_parameters: %TemplateParameters{email_signature: email_signature}},
        :email
      ),
      do: email_signature

  def get_message_signature_text(%__MODULE__{}, message_type) when message_type in [:sms, :email],
    do: ""

  @spec is_internal_managed_tenant?(tenant :: t) :: boolean
  def is_internal_managed_tenant?(tenant)

  def is_internal_managed_tenant?(%__MODULE__{
        case_management_enabled: true,
        iam_domain: iam_domain
      })
      when iam_domain != nil,
      do: true

  def is_internal_managed_tenant?(_tenant), do: false

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CaseContext.Person
    alias Hygeia.TenantContext.Tenant
    alias Hygeia.UserContext.User

    @spec preload(resource :: Tenant.t()) :: Tenant.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Tenant.t(),
            action :: :create | :details | :list | :update | :delete | :export_data,
            user :: :anonymous | User.t() | Person.t(),
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
