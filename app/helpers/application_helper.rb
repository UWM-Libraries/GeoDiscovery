# frozen_string_literal: true

module ApplicationHelper
  def render_html_value(args)
    simple_format(Array(args[:value]).flatten.join(" "))
  end

  def truncate_render_html_value(args)
    tag.div class: "truncate-abstract" do
      render_html_value(args)
    end
  end
end
