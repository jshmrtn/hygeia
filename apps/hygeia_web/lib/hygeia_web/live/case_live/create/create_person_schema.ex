defmodule HygeiaWeb.CaseLive.Create.CreatePersonSchema do
  @moduledoc false

  use Hygeia, :model

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Person.Sex
  alias Hygeia.TenantContext.Tenant
  alias Hygeia.UserContext.User

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :mobile, :string
    field :landline, :string
    field :suspected_duplicate_uuids, :string
    field :accepted_duplicate, :boolean
    field :accepted_duplicate_uuid, :binary_id
    field :accepted_duplicate_human_readable_id, :string
    field :search_params_hash, :integer
    field :employer, :string
    field :ism_case_id, :string
    field :ism_report_id, :string
    field :birth_date, :date
    field :sex, Sex

    embeds_one :clinical, Clinical, on_replace: :update
    embeds_one :address, Address, on_replace: :update

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
      person
      |> cast(attrs, [
        :uuid,
        :first_name,
        :last_name,
        :email,
        :mobile,
        :landline,
        :accepted_duplicate,
        :accepted_duplicate_uuid,
        :accepted_duplicate_human_readable_id,
        :suspected_duplicate_uuids,
        :search_params_hash,
        :tenant_uuid,
        :tracer_uuid,
        :supervisor_uuid,
        :employer,
        :ism_case_id,
        :ism_report_id,
        :birth_date,
        :sex
      ])
      |> cast_embed(:address)
      |> cast_embed(:clinical)

    if is_empty?(changeset) do
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
  end

  defp check_duplicate_acceptance(changeset) do
    changeset
    |> get_field(:suspected_duplicate_uuids)
    |> case do
      nil -> changeset
      "" -> changeset
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

  @spec to_person_attrs(schema :: %__MODULE__{}, default_country :: String.t() | nil) ::
          Hygeia.ecto_changeset_params()
  def to_person_attrs(
        %__MODULE__{
          first_name: first_name,
          last_name: last_name,
          email: email,
          mobile: mobile,
          landline: landline,
          employer: employer,
          sex: sex,
          address: address,
          birth_date: birth_date
        },
        default_country
      ) do
    attrs = %{
      first_name: first_name,
      last_name: last_name,
      contact_methods: [],
      birth_date: birth_date,
      employers: [],
      sex: sex,
      address:
        address
        |> Map.from_struct()
        |> Map.update!(:country, fn
          nil -> default_country
          other -> other
        end)
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

  @spec detect_duplicates(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def detect_duplicates(changeset) do
    {people, search} =
      changeset
      |> get_change(:people, [])
      |> Enum.map(
        &{&1,
         %{
           uuid: fetch_field!(&1, :uuid),
           first_name: fetch_field!(&1, :first_name),
           last_name: fetch_field!(&1, :last_name),
           mobile: fetch_field!(&1, :mobile),
           landline: fetch_field!(&1, :landline),
           email: fetch_field!(&1, :email)
         }}
      )
      |> Enum.map(fn {changeset, search_params} ->
        {changeset, search_params, :erlang.crc32(:erlang.term_to_binary(search_params))}
      end)
      |> Enum.reduce({[], []}, fn {person_changeset, person_search_params,
                                   person_search_params_hash},
                                  {people_acc, search_params_acc} ->
        if get_field(person_changeset, :search_params_hash) == person_search_params_hash do
          {[person_changeset | people_acc], search_params_acc}
        else
          {[
             put_change(person_changeset, :search_params_hash, person_search_params_hash)
             | people_acc
           ], [person_search_params | search_params_acc]}
        end
      end)

    people = Enum.reverse(people)

    duplicates = CaseContext.find_duplicates(search)

    new_people =
      people
      |> Enum.map(&{&1, Map.fetch(duplicates, fetch_field!(&1, :uuid))})
      |> Enum.map(fn
        {changeset, {:ok, duplicates}} ->
          put_change(changeset, :suspected_duplicate_uuids, Enum.join(duplicates, ","))

        {changeset, :error} ->
          changeset
      end)
      |> Enum.map(&check_duplicate_acceptance/1)
      |> Enum.map(&check_duplicate_acceptance_uuid/1)

    put_change(changeset, :people, new_people)
  end
end
