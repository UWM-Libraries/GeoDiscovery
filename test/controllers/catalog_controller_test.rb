# frozen_string_literal: true

require "test_helper"
require "json"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  SORT_TEST_TAG = "sort-script-test".freeze

  setup do
    @sort_test_ids = %w[sort-test-latin sort-test-chinese]
    Blacklight.default_index.connection.add(
      [
        build_sort_test_doc("sort-test-latin", "Alpha sort script test"),
        build_sort_test_doc("sort-test-chinese", "北京市城区街道图")
      ]
    )
    Blacklight.default_index.connection.commit
  end

  teardown do
    Blacklight.default_index.connection.delete_by_query("id:(#{@sort_test_ids.join(' ')})")
    Blacklight.default_index.connection.commit
  end

  test "should return admin view" do
    get "/catalog/mit-001145244/admin"
    assert_response :success
  end

  test "title sort deprioritizes non latin script titles" do
    get "/", params: { q: SORT_TEST_TAG, search_field: "all_fields", sort: "#{Settings.FIELDS.TITLE_SORT} asc" }

    assert_response :success
    assert_includes response.body, "Alpha sort script test"
    assert_includes response.body, "北京市城区街道图"
    assert_operator response.body.index("Alpha sort script test"), :<, response.body.index("北京市城区街道图")
  end

  private

  def build_sort_test_doc(id, title)
    fixture_doc.merge(
      "id" => id,
      "dct_title_s" => title,
      "dct_description_sm" => [SORT_TEST_TAG]
    )
  end

  def fixture_doc
    @fixture_doc ||= JSON.parse(
      Rails.root.join("test/fixtures/files/gbl_documents/index-map-stanford.json").read
    )
  end
end
