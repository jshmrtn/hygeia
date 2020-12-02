defmodule HygeiaPdfConfirmation do
  @moduledoc """
  PDF Generation
  """

  import Phoenix.View, only: [render_layout: 4]

  alias HygeiaPdfConfirmation.LayoutView

  @available_variations Hygeia.TenantContext.Tenant.TemplateVariation.__enum_map__()

  @type variation :: atom

  @spec available_variations() :: [variation()]
  def available_variations, do: @available_variations

  @doc false
  @spec render_pdf(variation :: variation, view :: atom, template :: String.t(), assigns :: list) ::
          binary
  def render_pdf(variation, view, template, assigns) when variation in @available_variations do
    {:ok, header_html_path} = Briefly.create(extname: ".html")

    header_html =
      LayoutView
      |> render_layout "#{variation}_pdf.html", assigns do
        LayoutView.render("#{variation}_header.html", assigns)
      end
      |> Phoenix.HTML.safe_to_string()

    File.write!(header_html_path, header_html)

    {:ok, footer_html_path} = Briefly.create(extname: ".html")

    footer_html =
      LayoutView
      |> render_layout "#{variation}_pdf.html", assigns do
        LayoutView.render("#{variation}_footer.html", assigns)
      end
      |> Phoenix.HTML.safe_to_string()

    File.write!(footer_html_path, footer_html)

    LayoutView
    |> render_layout "#{variation}_pdf.html", assigns do
      view.render("#{variation}_#{template}", assigns)
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
end
