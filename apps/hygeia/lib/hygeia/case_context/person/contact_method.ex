defmodule Hygeia.CaseContext.Case.ContactMethod do
  @moduledoc """
  Model for Contact Method Schema
  """

  use Hygeia, :model

  import EctoEnum

  defenum Type, :contact_method_type, ["mobile", "landline", "email", "other"]

  @type empty :: %__MODULE__{
          type: Type.t() | nil,
          comment: String.t() | nil,
          value: String.t() | nil
        }

  @type t :: %__MODULE__{
          type: Type.t(),
          comment: String.t() | nil,
          value: String.t()
        }

  embedded_schema do
    field :type, Type
    field :comment, :string
    field :value, :string
  end

  @doc false
  @spec changeset(contact_method :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(contact_method, attrs) do
    contact_method
    |> cast(attrs, [:uuid, :type, :comment, :value])
    |> fill_uuid
    |> validate_required([:type, :value])
    |> switch_type(fn
      :email, changeset ->
        validate_email(changeset, :value)

      :mobile, changeset ->
        validate_and_normalize_phone(changeset, :value, fn
          :mobile -> :ok
          :fixed_line_or_mobile -> :ok
          :personal_number -> :ok
          :unknown -> :ok
          _other -> {:error, "not a mobile number"}
        end)

      :landline, changeset ->
        validate_and_normalize_phone(changeset, :value, fn
          :fixed_line -> :ok
          :fixed_line_or_mobile -> :ok
          :voip -> :ok
          :personal_number -> :ok
          :unknown -> :ok
          _other -> {:error, "not a landline number"}
        end)

      :other, changeset ->
        changeset

      _other, changeset ->
        changeset
    end)
  end

  defp switch_type(changeset, callback) do
    changeset
    |> fetch_field!(:type)
    |> callback.(changeset)
  end
end
