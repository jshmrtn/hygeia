defmodule HygeiaWeb.CaseLive.Create.CreatePersonSchema do
  @moduledoc false

  use Hygeia, :model

  alias Hygeia.CaseContext
  alias Hygeia.CaseContext.Address
  alias Hygeia.CaseContext.Case
  alias Hygeia.CaseContext.Case.Clinical
  alias Hygeia.CaseContext.Person
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
    field :accepted_duplicate_case_uuid, :binary_id
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
        :accepted_duplicate_case_uuid,
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
      |> fill_uuid

    if is_person_empty?(changeset) do
      changeset
    else
      validate_changeset(changeset)
    end
  end

  @spec is_person_empty?(changeset :: Changeset.t()) :: boolean
  def is_person_empty?(changeset),
    do: is_empty?(changeset, [:search_params_hash, :suspected_duplicate_uuids])

  @spec validate_changeset(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_changeset(changeset) do
    changeset
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

  @spec upsert(
          schema :: %__MODULE__{},
          socket :: Phoenix.LiveView.Socket.t(),
          global :: %{
            :default_tenant_uuid => String.t(),
            optional(:copy_address_from_propagator) => boolean,
            optional(atom()) => term()
          },
          propagator_case :: Case.t() | nil
        ) :: Person.t()
  def upsert(schema, socket, global, propagator_case \\ nil)

  def upsert(
        %__MODULE__{
          accepted_duplicate_uuid: duplicate_uuid,
          tenant_uuid: tenant_uuid,
          address: address,
          email: email,
          mobile: mobile,
          landline: landline,
          employer: employer
        } = schema,
        socket,
        %{default_tenant_uuid: default_tenant_uuid} = global,
        propagator_case
      ) do
    changeset =
      duplicate_uuid
      |> case do
        nil ->
          tenant_uuid = tenant_uuid || default_tenant_uuid

          socket.assigns.tenants
          |> Enum.find(&match?(%Tenant{uuid: ^tenant_uuid}, &1))
          |> CaseContext.create_person_changeset(%{})
          |> Map.put(:errors, [])
          |> Map.put(:valid?, true)

        uuid ->
          uuid |> CaseContext.get_person!() |> CaseContext.change_person()
      end
      |> merge_flat_fields(schema)
      |> merge_address(address)
      |> copy_address(global, propagator_case)
      |> merge_contact_method(:mobile, mobile)
      |> merge_contact_method(:email, email)
      |> merge_contact_method(:landline, landline)
      |> merge_employer(employer)

    {:ok, person} =
      case duplicate_uuid do
        nil -> CaseContext.create_person(changeset)
        _id -> CaseContext.update_person(changeset)
      end

    person
  end

  defp merge_flat_fields(changeset, schema) do
    [:first_name, :last_name, :birth_date, :sex, :tenant_uuid]
    |> Enum.map(&{&1, Map.fetch!(schema, &1)})
    |> Enum.reduce(changeset, fn
      {_field, nil}, acc -> acc
      {field, value}, acc -> Ecto.Changeset.put_change(acc, field, value)
    end)
  end

  defp merge_address(changeset, address)

  defp merge_address(changeset, nil), do: changeset

  defp merge_address(changeset, address) do
    case Ecto.Changeset.fetch_field!(changeset, :address) do
      nil ->
        Ecto.Changeset.put_embed(changeset, :address, address)

      old_address ->
        Ecto.Changeset.put_embed(changeset, :address, Address.merge(old_address, address))
    end
  end

  defp copy_address(changeset, global, propagator_case)

  defp copy_address(changeset, _global, nil), do: changeset

  defp copy_address(changeset, %{copy_address_from_propagator: true}, %Case{
         person: %Person{address: address}
       }) do
    case Ecto.Changeset.fetch_field!(changeset, :address) do
      nil ->
        Ecto.Changeset.put_embed(changeset, :address, address)

      old_address ->
        Ecto.Changeset.put_embed(
          changeset,
          :address,
          address
          |> Address.merge(old_address)
          |> Ecto.Changeset.put_change(:uuid, old_address.uuid)
          |> Ecto.Changeset.apply_changes()
        )
    end
  end

  defp copy_address(changeset, _global, _propagator_case), do: changeset

  defp merge_contact_method(changeset, type, value)
  defp merge_contact_method(changeset, _type, nil), do: changeset

  defp merge_contact_method(changeset, type, value) do
    existing_contact_methods = Ecto.Changeset.fetch_field!(changeset, :contact_methods) || []

    if Enum.any?(existing_contact_methods, &match?(%{type: ^type, value: ^value}, &1)) do
      changeset
    else
      Ecto.Changeset.put_embed(changeset, :contact_methods, [
        %{type: type, value: value} | existing_contact_methods
      ])
    end
  end

  defp merge_employer(changeset, employer)
  defp merge_employer(changeset, nil), do: changeset

  defp merge_employer(changeset, employer) do
    existing_employers = Ecto.Changeset.fetch_field!(changeset, :employers) || []

    if Enum.any?(existing_employers, &match?(%{name: ^employer}, &1)) do
      changeset
    else
      Ecto.Changeset.put_embed(changeset, :employers, [%{name: employer} | existing_employers])
    end
  end
end
