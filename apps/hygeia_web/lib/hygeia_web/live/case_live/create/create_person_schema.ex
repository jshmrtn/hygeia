defmodule HygeiaWeb.CaseLive.Create.CreatePersonSchema do
  @moduledoc false

  use Hygeia, :model

  alias Hygeia.CaseContext
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  # TODO: Add additional fields

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :mobile, :string
    field :landline, :string
    field :suspected_duplicates_uuid, {:array, :binary_id}
    field :accepted_duplicate, :boolean
    field :accepted_duplicate_uuid, :binary_id
    field :accepted_duplicate_human_readable_id, :string
    field :employer, :string
    field :test_date, :date
    field :test_laboratory_report, :date
    field :test_kind, Hygeia.CaseContext.Case.Clinical.TestKind
    field :test_result, Hygeia.CaseContext.Case.Clinical.Result

    belongs_to :tenant, Tenant, references: :uuid, foreign_key: :tenant_uuid
    belongs_to :supervisor, User, references: :uuid, foreign_key: :supervisor_uuid
    belongs_to :tracer, User, references: :uuid, foreign_key: :tracer_uuid
  end

  @spec changeset(
          person :: %__MODULE__{} | Changeset.t(),
          attrs :: Hygeia.ecto_changeset_params()
        ) ::
          Ecto.Changeset.t()
  def changeset(person \\ %__MODULE__{}, attrs \\ %{}) do
    changeset =
      %Changeset{changes: changes} =
      cast(person, attrs, [
        :uuid,
        :first_name,
        :last_name,
        :email,
        :mobile,
        :landline,
        :accepted_duplicate,
        :accepted_duplicate_uuid,
        :accepted_duplicate_human_readable_id,
        :tenant_uuid,
        :tracer_uuid,
        :supervisor_uuid,
        :employer,
        :test_date,
        :test_laboratory_report,
        :test_kind,
        :test_result
      ])

    if Map.drop(changes, [:uuid]) == %{} do
      changeset
    else
      validate_changeset(changeset)
    end
  end

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
    |> fill_uuid
    |> validate_required([:uuid, :first_name, :last_name])
    |> validate_email(:email)
    |> validate_and_normalize_phone(:mobile, fn
      :mobile -> :ok
      :fixed_line_or_mobile -> :ok
      :personal_number -> :ok
      :unknown -> :ok
      _other -> {:error, "not a mobile number"}
    end)
    |> validate_and_normalize_phone(:landline, fn
      :fixed_line -> :ok
      :fixed_line_or_mobile -> :ok
      :voip -> :ok
      :personal_number -> :ok
      :unknown -> :ok
      _other -> {:error, "not a landline number"}
    end)
    |> detect_duplicates(:mobile)
    |> detect_duplicates(:landline)
    |> detect_duplicates(:email)
    |> detect_name_duplicates
    |> check_duplicate_acceptance
    |> check_duplicate_acceptance_uuid
  end

  defp detect_duplicates(changeset, field) do
    with nil <- get_field(changeset, :accepted_duplicate_uuid),
         value when is_binary(value) <- get_field(changeset, field),
         [_ | _] = suspected_duplicates <-
           CaseContext.list_people_by_contact_method(field, value) do
      put_change(
        changeset,
        :suspected_duplicates_uuid,
        suspected_duplicates
        |> Enum.map(& &1.uuid)
        |> Kernel.++(get_field(changeset, :suspected_duplicates_uuid) || [])
        |> Enum.uniq()
      )
    else
      nil -> changeset
      [] -> changeset
      _id -> changeset
    end
  end

  defp detect_name_duplicates(changeset) do
    with first_name when is_binary(first_name) <- get_field(changeset, :first_name),
         last_name when is_binary(last_name) <- get_field(changeset, :last_name),
         [_ | _] = suspected_duplicates <-
           CaseContext.list_people_by_name(first_name, last_name) do
      put_change(
        changeset,
        :suspected_duplicates_uuid,
        suspected_duplicates
        |> Enum.map(& &1.uuid)
        |> Kernel.++(get_field(changeset, :suspected_duplicates_uuid) || [])
        |> Enum.uniq()
      )
    else
      nil -> changeset
      [] -> changeset
    end
  end

  defp check_duplicate_acceptance(changeset) do
    changeset
    |> get_field(:suspected_duplicates_uuid)
    |> case do
      nil -> changeset
      [] -> changeset
      _other -> validate_required(changeset, [:accepted_duplicate])
    end
  end

  defp check_duplicate_acceptance_uuid(changeset) do
    changeset
    |> get_field(:accepted_duplicate)
    |> case do
      nil ->
        changeset

      false ->
        changeset

      true ->
        validate_required(changeset, [
          :accepted_duplicate_uuid,
          :accepted_duplicate_human_readable_id
        ])
    end
  end

  @spec to_person_attrs(schema :: %__MODULE__{}) :: Hygeia.ecto_changeset_params()
  def to_person_attrs(%__MODULE__{
        first_name: first_name,
        last_name: last_name,
        email: email,
        mobile: mobile,
        landline: landline,
        employer: employer
      }) do
    attrs = %{
      first_name: first_name,
      last_name: last_name,
      contact_methods: [],
      employers: []
    }

    attrs =
      if is_nil(mobile),
        do: attrs,
        else: update_in(attrs.contact_methods, &[%{type: :mobile, value: mobile} | &1])

    attrs =
      if is_nil(landline),
        do: attrs,
        else: update_in(attrs.contact_methods, &[%{type: :landline, value: landline} | &1])

    attrs =
      if is_nil(email),
        do: attrs,
        else: update_in(attrs.contact_methods, &[%{type: :email, value: email} | &1])

    if is_nil(employer),
      do: attrs,
      else: update_in(attrs.employers, &[%{name: employer} | &1])
  end
end
