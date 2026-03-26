# frozen_string_literal: true

require "test_helper"

class FacetIconStylesTest < ActiveSupport::TestCase
  STYLESHEET_PATH = Rails.root.join("app/assets/stylesheets/modules/_accordions.scss").freeze

  test "facet accordion icons inherit the button text color" do
    stylesheet = STYLESHEET_PATH.read

    assert_includes stylesheet, "color: currentColor;"
  end
end
