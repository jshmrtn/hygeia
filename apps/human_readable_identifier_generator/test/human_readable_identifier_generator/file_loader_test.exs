defmodule HumanReadableIdentifierGenerator.FileLoaderTest do
  @moduledoc false
  use ExUnit.Case
  alias HumanReadableIdentifierGenerator.FileLoader

  @test_file Application.app_dir(
               :human_readable_identifier_generator,
               "priv/data/test/latin.txt"
             )

  test "should load file" do
    result = FileLoader.read(@test_file)

    assert Enum.member?(result, "abaddir")

    assert Enum.member?(result, "aeneam")

    assert result |> Enum.uniq() |> Enum.count() == Enum.count(result)
  end

  test "should contain all the words from the file" do
    result = FileLoader.read(@test_file)

    # Test the first word
    assert Enum.member?(result, "abaddir")

    # Test the last word
    assert Enum.member?(result, "aeneam")
  end

  test "should only contain unique words" do
    result = FileLoader.read(@test_file)
    # Test the length of the Enum after making it unique
    assert result |> Enum.uniq() |> Enum.count() == Enum.count(result)
  end

  test "should contain exactly the same amount of words from the list" do
    result = FileLoader.read(@test_file)
    # Test the length of the Enum after making it unique
    assert Enum.count(result) == 30
  end
end
