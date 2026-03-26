# frozen_string_literal: true

require "test_helper"

class OpenindexmapsTemplateTest < ActiveSupport::TestCase
  TEMPLATE_PATH = Rails.root.join("app/assets/javascripts/geoblacklight/templates/index_map_info.hbs").freeze

  test "index map preview images have empty alt text" do
    template = TEMPLATE_PATH.read

    assert_includes template, 'alt=""'
  end

  test "linked index map preview images label the link for assistive technology" do
    template = TEMPLATE_PATH.read

    assert_includes template, 'aria-label="{{#if title}}Open preview image for {{title}}'
  end
end
