# frozen_string_literal: true

require "test_helper"

class OpenindexmapsTemplateTest < ActiveSupport::TestCase
  TEMPLATE_PATH = Rails.root.join("app/assets/javascripts/geoblacklight/templates/index_map_info.hbs").freeze
  PATCH_PATH = Rails.root.join("app/assets/javascripts/geoblacklight/modules/util_a11y_patch.js").freeze

  test "index map preview images have empty alt text" do
    template = TEMPLATE_PATH.read

    assert_includes template, 'alt=""'
  end

  test "linked index map preview images label the link for assistive technology" do
    template = TEMPLATE_PATH.read

    assert_includes template, 'aria-label="{{#if title}}Open website for {{title}}'
  end

  test "index map popup html is hardened with runtime accessibility attributes" do
    patch = PATCH_PATH.read

    assert_includes patch, 'image.setAttribute("alt", "")'
    assert_includes patch, 'link.setAttribute("aria-label", previewLinkLabel(data))'
  end
end
