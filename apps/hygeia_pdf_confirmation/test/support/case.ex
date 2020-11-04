defmodule HygeiaPdfConfirmation.Case do
  @moduledoc """
  Helper to make PDF Testing easier.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import unquote(__MODULE__),
        only: [
          pdf_string: 1,
          pdf_string_from_file: 1
        ]
    end
  end

  @spec pdf_string(pdf_binary :: binary) :: String.t()
  def pdf_string(pdf_binary) do
    assert "%PDF" <> _ = pdf_binary

    {:ok, pdf_path} = Briefly.create(extname: ".pdf")
    File.write(pdf_path, pdf_binary)

    pdf_string_from_file(pdf_path)
  end

  @spec pdf_string_from_file(pdf_path :: Path.t()) :: String.t()
  def pdf_string_from_file(pdf_path) do
    {:ok, txt_path} = Briefly.create(extname: ".text")

    {_, 0} = System.cmd("pdftotext", [pdf_path, txt_path], env: %{})

    File.read!(txt_path)
  end
end
