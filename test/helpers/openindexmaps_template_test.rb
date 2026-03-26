# frozen_string_literal: true

require "test_helper"

class OpenindexmapsTemplateTest < ActiveSupport::TestCase
  PATCH_PATH = Rails.root.join("app/assets/javascripts/geoblacklight/modules/util_a11y_patch.js").freeze

  test "index map popup images get empty alt text" do
    patch = PATCH_PATH.read

    assert_includes patch, 'image.setAttribute("alt", "")'
  end

  test "linked index map popup images label the website destination" do
    patch = PATCH_PATH.read

    assert_includes patch, 'return "Open website for " + data.title;'
    assert_includes patch, 'return "Open website for " + data.label;'
  end

  test "index map popup html is hardened with runtime accessibility attributes" do
    patch = PATCH_PATH.read

    assert_includes patch, 'image.setAttribute("alt", "")'
    assert_includes patch, 'link.setAttribute("aria-label", websiteLinkLabel(data))'
  end
end
