module ArticlesHelper
  # Renders an Article body (see Article) as escaped HTML: paragraphs,
  # "## " headings and "- " bullet lists. Every piece of text goes through
  # the normal tag helpers, so nothing in the body is treated as HTML.
  def article_body(text)
    blocks = text.to_s.gsub("\r\n", "\n").split(/\n{2,}/).map(&:strip).reject(&:empty?)
    safe_join(blocks.map { |block| article_block(block) }, "\n")
  end

  private

  def article_block(block)
    lines = block.lines.map(&:strip)
    if lines.one? && lines.first.start_with?("## ")
      tag.h2(lines.first.delete_prefix("## "), class: "h5 mt-4")
    elsif lines.all? { |line| line.start_with?("- ") }
      tag.ul(safe_join(lines.map { |line| tag.li(line.delete_prefix("- ")) }))
    else
      tag.p(safe_join(lines, tag.br))
    end
  end
end
