defmodule Hygeia.CommunicationContext.Email do
  @moduledoc """
  Model for Email
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.CaseContext.Case
  alias Hygeia.CommunicationContext.Direction
  alias Hygeia.Repo
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.TenantContext.Tenant.Smtp.DKIM

  defenum Status, :email_status, [
    :in_progress,
    :success,
    :temporary_failure,
    :permanent_failure,
    :retries_exceeded
  ]

  @type empty :: %__MODULE__{
          direction: Direction.t() | nil,
          status: Status.t() | nil,
          message: binary() | nil,
          recipient: String.t() | nil,
          subject: String.t() | nil,
          body: String.t() | nil,
          last_try: DateTime.t() | nil,
          case_uuid: String.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          tenant: Ecto.Schema.has_one(Tenant.t()) | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @type t :: %__MODULE__{
          direction: Direction.t(),
          status: Status.t(),
          message: binary(),
          recipient: String.t() | nil,
          subject: String.t() | nil,
          body: String.t() | nil,
          last_try: DateTime.t(),
          case_uuid: String.t(),
          case: Ecto.Schema.belongs_to(Case.t()),
          tenant: Ecto.Schema.has_one(Tenant.t()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "emails" do
    field :direction, Direction
    field :last_try, :utc_datetime_usec
    field :status, Status
    field :message, :binary

    field :recipient, :string, virtual: true
    field :subject, :string, virtual: true
    field :body, :string, virtual: true

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid
    has_one :tenant, through: [:case, :tenant]

    timestamps()
  end

  @spec changeset(
          email :: resource | Changeset.t(resource),
          attrs :: Hygeia.ecto_changeset_params()
        ) :: Ecto.Changeset.t(resource)
        when resource: t() | empty()
  def changeset(email, attrs),
    do:
      email
      |> cast(attrs, [
        :uuid,
        :direction,
        :status,
        :message,
        :last_try,
        :recipient,
        :subject,
        :body
      ])
      |> fill_uuid()
      |> maybe_generate_message()
      |> validate_required([:uuid, :direction, :status, :message])
      |> assoc_constraint(:case)

  defp maybe_generate_message(changeset) do
    if Enum.any?(
         [:recipient, :subject, :body],
         &(not is_nil(Changeset.fetch_field!(changeset, &1)))
       ) do
      changeset
      |> validate_required([:recipient, :subject, :body])
      |> generate_message()
    else
      changeset
    end
  end

  defp generate_message(%Changeset{valid?: false} = changeset), do: changeset

  defp generate_message(
         %Changeset{valid?: true, data: %__MODULE__{case: case, tenant: tenant}} = changeset
       ) do
    %Case{
      person: person,
      tenant: %Tenant{name: from_name, from_email: from_email}
    } = Repo.preload(case, person: [], tenant: [])

    if TenantContext.tenant_has_outgoing_mail_configuration?(tenant) do
      to_name =
        [person.first_name, person.last_name]
        |> Enum.reject(&(&1 in ["", nil]))
        |> Enum.join(" ")

      encoding_options =
        case tenant do
          %Tenant{outgoing_mail_configuration: %Tenant.Smtp{enable_dkim: false}} ->
            []

          %Tenant{
            outgoing_mail_configuration: %Tenant.Smtp{enable_dkim: true, dkim: %DKIM{} = config}
          } ->
            [dkim: DKIM.to_gen_smtp_opts(config)]
        end

      put_change(
        changeset,
        :message,
        :mimemail.encode(
          {"text", "plain",
           [
             {"Subject", Changeset.fetch_field!(changeset, :subject)},
             {"From", :smtp_util.combine_rfc822_addresses([{from_name, from_email}])},
             {"To",
              :smtp_util.combine_rfc822_addresses([
                {to_name, Changeset.fetch_field!(changeset, :recipient)}
              ])},
             {"Auto-submitted", "yes"},
             {"X-Auto-Response-Suppress", "All"},
             {"Precedence", "auto_reply"},
             {"Date", Calendar.strftime(DateTime.utc_now(), "%a, %-d %b %Y %X %z")},
             {"Message-ID", Changeset.fetch_field!(changeset, :uuid)},
             {"Content-Type", "text/plain"},
             {"Content-Transfer-Encoding", "7bit"}
           ], [], Changeset.fetch_field!(changeset, :body)},
          encoding_options
        )
      )
    else
      add_error(changeset, :tenant, "has no outgoing email configuration")
    end
  end

  defimpl Hygeia.Authorization.Resource do
    alias Hygeia.CommunicationContext.Email
    alias Hygeia.UserContext.User

    @spec preload(resource :: Email.t()) :: Email.t()
    def preload(resource), do: resource

    @spec authorized?(
            resource :: Email.t(),
            action :: :create,
            user :: :anonymous | User.t(),
            meta :: %{atom() => term}
          ) :: boolean
    def authorized?(_email, action, :anonymous, _meta)
        when action in [:create],
        do: false

    def authorized?(_email, :create, user, %{case: %Case{tenant_uuid: tenant_uuid}}),
      do:
        Enum.any?(
          [:tracer, :supervisor, :super_user, :admin],
          &User.has_role?(user, &1, tenant_uuid)
        )
  end
end
