defmodule HumanReadableIdentifierGeneratorTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias HumanReadableIdentifierGenerator
  alias HumanReadableIdentifierGenerator.FileLoader

  @test_file Application.app_dir(
               :human_readable_identifier_generator,
               "priv/data/test/latin.txt"
             )

  setup %{test: test} do
    server =
      start_supervised!({
        HumanReadableIdentifierGenerator.Storage,
        # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
        name: :"#{__MODULE__}.#{test}",
        base_path: Application.app_dir(:human_readable_identifier_generator, "priv/data/test")
      })

    {:ok, server: server}
  end

  describe "fetch_human_readable_id/1" do
    test "returns a valid word", %{server: server} do
      process_id = "05b4d3a2-80b8-48a1-90d8-4fab71f178c6"

      assert {:ok, result} =
               HumanReadableIdentifierGenerator.fetch_human_readable_id(process_id, server)

      assert is_binary(result)

      assert %{"one" => one, "two" => two, "digits" => digits} =
               Regex.named_captures(~r/^(?<one>\w+)-(?<two>\w+)-(?<digits>\d+)$/, result)

      assert Enum.member?(FileLoader.read(@test_file), one)
      assert Enum.member?(FileLoader.read(@test_file), two)
      assert digits == digits |> String.to_integer() |> to_string
    end
  end
end
