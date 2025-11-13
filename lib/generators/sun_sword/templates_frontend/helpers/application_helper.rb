module ApplicationHelper
  def post_to(path, options = {}, &block)
    link_to path, { data: { turbo_method: :post } }.deep_merge(options), &block
  end

  def delete_to(path, options = {}, &block)
    link_to path, { data: { turbo_method: :delete } }.deep_merge(options), &block
  end

  def patch_to(path, options = {}, &block)
    link_to path, { data: { turbo_method: :patch } }.deep_merge(options), &block
  end

  def flash_type(flash)
    flash.map { |type, msg| type }[0]
  end

  def truncate_html(html, opts = {})
    html_string = TruncateHtml::HtmlString.new(html)
    TruncateHtml::HtmlTruncator.new(html_string, opts).truncate
  end
end
