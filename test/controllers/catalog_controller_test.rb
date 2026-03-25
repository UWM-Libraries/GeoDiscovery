# frozen_string_literal: true

require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "should return admin view" do
    get "/catalog/mit-001145244/admin"
    assert_response :success
  end

  test "index subtitle uses temporal coverage field" do
    index_field = CatalogController.blacklight_config.index_fields[Settings.FIELDS.TEMPORAL_COVERAGE]

    assert_equal :format_index_temporal_coverage, index_field.helper_method
  end
end
