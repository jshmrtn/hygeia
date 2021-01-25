defmodule Hygeia.CommunicationContext do
  @moduledoc """
  The CommunicationContext context.
  """

  use Hygeia, :context

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Person
  alias Hygeia.CommunicationContext.Email
  alias Hygeia.CommunicationContext.SMS
  alias Hygeia.TenantContext
  alias Hygeia.TenantContext.Tenant

  @doc """
  Returns the list of emails.

  ## Examples

      iex> list_emails()
      [%Emails{}, ...]

  """
  @spec list_emails :: [Email.t()]
  def list_emails, do: Repo.all(Email)

  @spec list_emails_to_send(limit :: pos_integer()) :: [Email.t()]
  def list_emails_to_send(limit \\ 100), do: Repo.all(list_emails_to_send_query(limit))

  @spec list_emails_to_send_query(limit :: pos_integer()) :: Ecto.Query.t()
  def list_emails_to_send_query(limit \\ 100),
    do:
      from(email in Email,
        where:
          email.status in [:in_progress, :temporary_failure] and email.direction == :outgoing and
            (is_nil(email.last_try) or
               email.updated_at +
                 fragment(
                   "LEAST(?, ?)",
                   2 * fragment("AGE(?, ?)", email.last_try, email.inserted_at),
                   fragment("INTERVAL '1 hour'")
                 ) <=
                 ^NaiveDateTime.utc_now()),
        lock: "FOR UPDATE",
        preload: [:tenant],
        limit: ^limit
      )

  @spec list_emails_to_abort :: [Email.t()]
  def list_emails_to_abort, do: Repo.all(list_emails_to_abort_query())

  @spec list_emails_to_abort_query :: Ecto.Query.t()
  def list_emails_to_abort_query,
    do:
      from(email in Email,
        where:
          email.status in [:in_progress, :temporary_failure] and email.direction == :outgoing and
            email.inserted_at <= ago(1, "week"),
        lock: "FOR UPDATE"
      )

  @doc """
  Gets a single emails.

  Raises `Ecto.NoResultsError` if the Email does not exist.

  ## Examples

      iex> get_email!(123)
      %Emails{}

      iex> get_email!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_email!(id :: String.t()) :: Email.t()
  def get_email!(id), do: Repo.get!(Email, id)

  @doc """
  Creates a email.

  ## Examples

      iex> create_email(%{field: value})
      {:ok, %Emails{}}

      iex> create_email(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_email(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Email.t()} | {:error, Ecto.Changeset.t(Email.t())}
  def create_email(case, attrs \\ %{}),
    do:
      case
      |> change_email_create(attrs)
      |> versioning_insert()
      |> broadcast("emails", :create, & &1.uuid, &["emails:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @spec create_outgoing_email(case :: Case.t(), subject :: String.t(), body :: String.t()) ::
          {:ok, Email.t()}
          | {:error, Ecto.Changeset.t(Email.t()) | :no_email | :no_outgoing_mail_configuration}
  def create_outgoing_email(case, subject, body) do
    %Case{
      person: %Person{contact_methods: contact_methods} = person,
      tenant: tenant
    } = Repo.preload(case, person: [], tenant: [])

    cond do
      !CaseContext.person_has_email?(person) ->
        {:error, :no_email}

      !TenantContext.tenant_has_outgoing_mail_configuration?(tenant) ->
        {:error, :no_outgoing_mail_configuration}

      true ->
        to_email =
          Enum.find_value(contact_methods, fn
            %{type: :email, value: value} -> value
            _contact_method -> false
          end)

        create_email(case, %{
          recipient: to_email,
          subject: subject,
          body: body,
          status: :in_progress,
          direction: :outgoing
        })
    end
  end

  @doc """
  Updates an email.

  ## Examples

      iex> update_email(email, %{field: new_value})
      {:ok, %Emails{}}

      iex> update_email(email, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_email(email :: Email.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, Email.t()} | {:error, Ecto.Changeset.t(Email.t())}
  def update_email(%Email{} = email, attrs),
    do:
      email
      |> change_email(attrs)
      |> versioning_update()
      |> broadcast("emails", :update, & &1.uuid, &["emails:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Deletes an email.

  ## Examples

      iex> delete_email(email)
      {:ok, %Email{}}

      iex> delete_email(email)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_email(email :: Email.t()) ::
          {:ok, Email.t()} | {:error, Ecto.Changeset.t(Email.t())}
  def delete_email(%Email{} = email),
    do:
      email
      |> change_email()
      |> versioning_delete()
      |> broadcast("emails", :delete, & &1.uuid, &["emails:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email changes.

  ## Examples

      iex> change_email(email)
      %Ecto.Changeset{data: %Email{}}

  """
  @spec change_email(email :: Email.t() | Email.empty(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Email.t() | Email.empty())
  def change_email(%Email{} = email, attrs \\ %{}), do: Email.changeset(email, attrs)

  @spec change_email_create(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(Email.t() | Email.empty())
  def change_email_create(case, attrs \\ %{}) do
    case = %Case{tenant: tenant} = Repo.preload(case, tenant: [])

    case
    |> Ecto.build_assoc(:emails)
    |> Map.put(:case, case)
    |> Map.put(:tenant, tenant)
    |> change_email(attrs)
  end

  @doc """
  Returns the list of sms.

  ## Examples

      iex> list_sms()
      [%SMSs{}, ...]

  """
  @spec list_sms :: [SMS.t()]
  def list_sms, do: Repo.all(SMS)

  @spec list_sms_to_send :: [SMS.t()]
  def list_sms_to_send, do: Repo.all(list_sms_to_send_query())

  @spec list_sms_to_send_query :: Ecto.Query.t()
  def list_sms_to_send_query,
    do:
      from(sms in SMS,
        where: sms.status == :in_progress and sms.direction == :outgoing,
        lock: "FOR UPDATE",
        preload: [:tenant]
      )

  @doc """
  Gets a single sms.

  Raises `Ecto.NoResultsError` if the SMS does not exist.

  ## Examples

      iex> get_sms!(123)
      %SMSs{}

      iex> get_sms!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_sms!(id :: String.t()) :: SMS.t()
  def get_sms!(id), do: Repo.get!(SMS, id)

  @doc """
  Creates a sms.

  ## Examples

      iex> create_sms(%{field: value})
      {:ok, %SMSs{}}

      iex> create_sms(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_sms(case :: Case.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, SMS.t()} | {:error, Ecto.Changeset.t(SMS.t())}
  def create_sms(case, attrs \\ %{}),
    do:
      case
      |> Ecto.build_assoc(:sms)
      |> change_sms(attrs)
      |> versioning_insert()
      |> broadcast("sms", :create, & &1.uuid, &["sms:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @spec create_outgoing_sms(case :: Case.t(), message :: String.t()) ::
          {:ok, SMS.t()}
          | {:error, Ecto.Changeset.t(SMS.t()) | :no_mobile_number | :sms_config_missing}
  def create_outgoing_sms(case, message) do
    %Case{person: %Person{contact_methods: contact_methods} = person, tenant: %Tenant{} = tenant} =
      Repo.preload(case, person: [], tenant: [])

    cond do
      !CaseContext.person_has_mobile_number?(person) ->
        {:error, :no_mobile_number}

      !TenantContext.tenant_has_outgoing_sms_configuration?(tenant) ->
        {:error, :sms_config_missing}

      true ->
        phone_number =
          Enum.find_value(contact_methods, fn
            %{type: :mobile, value: value} -> value
            _contact_method -> false
          end)

        create_sms(case, %{
          direction: :outgoing,
          status: :in_progress,
          message: message,
          number: phone_number
        })
    end
  end

  @doc """
  Updates an sms.

  ## Examples

      iex> update_sms(sms, %{field: new_value})
      {:ok, %SMSs{}}

      iex> update_sms(sms, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_sms(sms :: SMS.t(), attrs :: Hygeia.ecto_changeset_params()) ::
          {:ok, SMS.t()} | {:error, Ecto.Changeset.t(SMS.t())}
  def update_sms(%SMS{} = sms, attrs),
    do:
      sms
      |> change_sms(attrs)
      |> versioning_update()
      |> broadcast("sms", :update, & &1.uuid, &["sms:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Deletes an sms.

  ## Examples

      iex> delete_sms(sms)
      {:ok, %SMS{}}

      iex> delete_sms(sms)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_sms(sms :: SMS.t()) ::
          {:ok, SMS.t()} | {:error, Ecto.Changeset.t(SMS.t())}
  def delete_sms(%SMS{} = sms),
    do:
      sms
      |> change_sms()
      |> versioning_delete()
      |> broadcast("sms", :delete, & &1.uuid, &["sms:case:#{&1.case_uuid}"])
      |> versioning_extract()

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sms changes.

  ## Examples

      iex> change_sms(sms)
      %Ecto.Changeset{data: %SMS{}}

  """
  @spec change_sms(sms :: SMS.t() | SMS.empty(), attrs :: Hygeia.ecto_changeset_params()) ::
          Ecto.Changeset.t(SMS.t() | SMS.empty())
  def change_sms(%SMS{} = sms, attrs \\ %{}), do: SMS.changeset(sms, attrs)
end
