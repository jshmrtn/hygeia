defmodule Hygeia.AutoTracingContext.AutoTracing do
  @moduledoc """
  Auto Tracing Model
  """

  use Hygeia, :model

  import EctoEnum

  alias Hygeia.AutoTracingContext.Employer
  alias Hygeia.AutoTracingContext.Transmission
  alias Hygeia.CaseContext.Case

  defenum Step, :auto_tracing_step, [
    :start,
    :contact,
    :employer,
    :vaccination,
    :covid_app,
    :clinical,
    :transmission,
    :finished
  ]

  @type empty :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          current_step: Step.t() | nil,
          closed: boolean | nil,
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()) | nil,
          case_uuid: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @type t :: %__MODULE__{
          uuid: Ecto.UUID.t(),
          current_step: Step.t(),
          closed: boolean,
          employer: Employer.t() | nil,
          transmission: Transmission.t() | nil,
          case: Ecto.Schema.belongs_to(Case.t()),
          case_uuid: Ecto.UUID.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {Phoenix.Param, key: :uuid}

  schema "auto_tracings" do
    field :closed, :boolean
    field :current_step, Step

    embeds_one :employer, Employer
    embeds_one :transmission, Transmission

    belongs_to :case, Case, references: :uuid, foreign_key: :case_uuid

    timestamps()
  end

  @spec changeset(auto_tracing :: t | empty, attrs :: Hygeia.ecto_changeset_params()) ::
          Changeset.t()
  def changeset(auto_tracing, attrs) do
    auto_tracing
    |> cast(attrs, [:closed, :current_step, :case_uuid])
    |> validate_required([:current_step, :case_uuid])
    |> cast_embed(:employer)
    |> cast_embed(:transmission)
  end
end
