defmodule HygeiaPdfConfirmation do
  @moduledoc """
  PDF Generation
  """

  @spec template_variations :: [String.t()]
  def template_variations do
    variations =
      template_root_path()
      |> Path.join("**/*.html.eex")
      |> Path.wildcard()
      |> Enum.map(&Path.basename(&1, ".html.eex"))
      |> Enum.uniq()

    for variation <- variations do
      ensure_template_exists("isolation", variation)
      ensure_template_exists("layout/body", variation)
      ensure_template_exists("layout/header", variation)
      ensure_template_exists("layout/footer", variation)
      ensure_template_exists("quarantine", variation)
      ensure_template_exists("isolation_end", variation)
    end

    variations
  end

  @doc false
  @spec template_path(type :: String.t(), template :: String.t()) :: Path.t()
  def template_path(type, template),
    do: Path.join([template_root_path(), type, template <> ".html.eex"])

  @spec render_pdf(variation :: String.t() | nil, template :: String.t(), assigns :: list) ::
          binary
  def render_pdf(variation, template, assigns)

  def render_pdf(nil, template, assigns),
    do: render_pdf(hd(template_variations()), template, assigns)

  def render_pdf(variation, template, assigns) do
    {:ok, header_html_path} = Briefly.create(extname: ".html")

    header_html =
      variation
      |> render_layout "layout/body", assigns do
        render(variation, "layout/header", assigns)
      end
      |> Phoenix.HTML.safe_to_string()

    File.write!(header_html_path, header_html)

    {:ok, footer_html_path} = Briefly.create(extname: ".html")

    footer_html =
      variation
      |> render_layout "layout/body", assigns do
        render(variation, "layout/footer", assigns)
      end
      |> Phoenix.HTML.safe_to_string()

    File.write!(footer_html_path, footer_html)

    variation
    |> render_layout "layout/body", assigns do
      render(variation, template, assigns)
    end
    |> Phoenix.HTML.safe_to_string()
    |> PdfGenerator.generate_binary!(
      delete_temporary: true,
      shell_params: [
        "--header-spacing",
        "10",
        "--header-html",
        header_html_path,
        "--footer-spacing",
        "10",
        "--footer-html",
        footer_html_path,
        "--margin-left",
        "3cm",
        "--margin-right",
        "3cm",
        "--margin-top",
        "5cm",
        "--margin-bottom",
        "2cm"
      ]
    )
  end

  defp template_root_path,
    do:
      Application.get_env(
        :hygeia_pdf_confirmation,
        :template_root_path,
        Application.app_dir(:hygeia_pdf_confirmation, "priv/templates")
      )

  defp ensure_template_exists(type, variation) do
    unless File.exists?(template_path(type, variation)) do
      raise "Template #{type} does not exist for #{variation}"
    end
  end

  defp render_layout(variation, type, assigns, do: block) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put(:inner_content, block)

    render(variation, type, assigns)
  end

  defp render(variation, type, assigns),
    do:
      EEx.eval_file(
        HygeiaPdfConfirmation.template_path(type, variation),
        [assigns: Enum.to_list(assigns) ++ [template_root: template_root_path()]],
        engine: Phoenix.HTML.Engine
      )
end
