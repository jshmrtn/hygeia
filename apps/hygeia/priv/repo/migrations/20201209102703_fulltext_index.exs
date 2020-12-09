# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hygeia.Repo.Migrations.FulltextIndex do
  @moduledoc false

  use Hygeia, :migration

  import Ecto.Query

  alias Hygeia.Repo

  @origin_country Application.compile_env!(:hygeia, [:phone_number_parsing_origin_country])

  def change do
    execute(
      """
      CREATE FUNCTION
        JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(jsonb[], jsonpath)
        RETURNS TSVECTOR
        IMMUTABLE
        CALLED ON NULL INPUT
        AS $$
          BEGIN
            RETURN JSONB_TO_TSVECTOR(
              'german',
              COALESCE(
                JSONB_PATH_QUERY_ARRAY(
                  ARRAY_TO_JSON($1)::jsonb,
                  $2
                ),
                '[]'::jsonb
              ),
              '["all"]'
            );
          END;
        $$ LANGUAGE plpgsql;
      """,
      """
        DROP FUNCTION JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(jsonb[], jsonpath);
      """
    )

    execute(
      """
      ALTER
        TABLE people
        ADD fulltext TSVECTOR
          GENERATED ALWAYS AS (
            TO_TSVECTOR('german', uuid::text) ||
            TO_TSVECTOR('german', human_readable_id) ||
            TO_TSVECTOR('german', COALESCE(first_name, '')) ||
            TO_TSVECTOR('german', COALESCE(last_name, '')) ||
            JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(contact_methods, '$[*].value') ||
            JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(external_references, '$[*].value') ||
            COALESCE(JSONB_TO_TSVECTOR('german', address, '["all"]'), TO_TSVECTOR('german', '')) ||
            JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(employers, '$[*].name')
          ) STORED
      """,
      """
        ALTER
          TABLE people
          DROP COLUMN fulltext
      """
    )

    create index(:people, [:fulltext], using: :gin)

    execute(
      """
      ALTER
        TABLE cases
        ADD fulltext TSVECTOR
          GENERATED ALWAYS AS (
            TO_TSVECTOR('german', uuid::text) ||
            TO_TSVECTOR('german', human_readable_id) ||
            JSONB_ARRAY_TO_TSVECTOR_WITH_PATH(external_references, '$[*].value')
          ) STORED
      """,
      """
        ALTER
          TABLE cases
          DROP COLUMN fulltext
      """
    )

    create index(:cases, [:fulltext], using: :gin)

    execute(
      """
      ALTER
        TABLE organisations
        ADD fulltext TSVECTOR
          GENERATED ALWAYS AS (
            TO_TSVECTOR('german', uuid::text) ||
            TO_TSVECTOR('german', name) ||
            TO_TSVECTOR('german', COALESCE(notes, '')) ||
            COALESCE(JSONB_TO_TSVECTOR('german', address, '["all"]'), TO_TSVECTOR('german', ''))
          ) STORED
      """,
      """
        ALTER
          TABLE organisations
          DROP COLUMN fulltext
      """
    )

    create index(:organisations, [:fulltext], using: :gin)

    execute(
      &reformat_phone_international/0,
      &reformat_phone_e164/0
    )
  end

  defp reformat_phone_international, do: reformat_phone(:international)
  defp reformat_phone_e164, do: reformat_phone(:e164)

  defp reformat_phone(target_format) do
    Repo.transaction(fn ->
      from(person in "people",
        where:
          fragment(~S[?::jsonb <@ ANY (?)], ^%{type: :mobile}, person.contact_methods) or
            fragment(~S[?::jsonb <@ ANY (?)], ^%{type: :landline}, person.contact_methods),
        select: %{uuid: person.uuid, contact_methods: person.contact_methods},
        lock: "FOR UPDATE"
      )
      |> Repo.stream()
      |> Stream.filter(fn %{contact_methods: contact_methods} ->
        Enum.any?(
          contact_methods,
          &match?(%{"type" => type} when type in ["mobile", "landline"], &1)
        )
      end)
      |> Enum.reduce(Ecto.Multi.new(), fn %{uuid: uuid, contact_methods: contact_methods},
                                          multi ->
        Ecto.Multi.update_all(multi, uuid, from(person in "people", where: person.uuid == ^uuid),
          set: [
            contact_methods:
              Enum.map(contact_methods, fn
                %{"type" => type, "value" => value} = contact_method
                when type in ["mobile", "landline"] ->
                  with {:ok, parsed_number} <- ExPhoneNumber.parse(value, @origin_country),
                       true <- ExPhoneNumber.is_valid_number?(parsed_number),
                       value <- ExPhoneNumber.Formatting.format(parsed_number, target_format) do
                    %{contact_method | "value" => value}
                  end

                other ->
                  other
              end)
          ]
        )
      end)
      |> Repo.transaction()
    end)
  end
end
