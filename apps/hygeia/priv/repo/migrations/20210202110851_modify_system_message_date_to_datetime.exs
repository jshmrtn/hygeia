# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.ModifySystemMessageDateToDatetime do
  @moduledoc false

  use Hygeia, :migration

  def up do
    alter table(:system_messages) do
      modify :start_date, :utc_datetime_usec
      modify :end_date, :utc_datetime_usec
    end
  end
end
