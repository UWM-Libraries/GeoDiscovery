# frozen_string_literal: true

require "test_helper"
require "json"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  SORT_TEST_TAG = "sort-script-test"

  setup do
    @sort_test_ids = %w[sort-test-latin sort-test-chinese]
    Blacklight.default_index.connection.add(
      [
        build_sort_test_doc("sort-test-latin", "Alabama county boundaries"),
        build_sort_test_doc("sort-test-chinese", "北京市城区街道图")
      ]
    )
    Blacklight.default_index.connection.commit
  end

  teardown do
    Blacklight.default_index.connection.delete_by_query("id:(#{@sort_test_ids.join(" ")})")
    Blacklight.default_index.connection.commit
  end

  test "should return admin view" do
    get "/catalog/mit-001145244/admin"
    assert_response :success
  end

  test "index subtitle uses temporal coverage field" do
    index_field = CatalogController.blacklight_config.index_fields[Settings.FIELDS.TEMPORAL_COVERAGE]

    assert_equal :format_index_temporal_coverage, index_field.helper_method
  end
  test "blank search result titles render transliteration for non latin titles" do
    get "/", params: {q: SORT_TEST_TAG, search_field: "all_fields", sort: "#{Settings.FIELDS.TITLE_SORT} asc"}

    assert_response :success
    assert_includes response.body, "bei jing shi cheng qu jie dao tu"
    assert_includes response.body, "北京市城区街道图"
  end

  test "transliterated title sort keeps romanized titles in latin order" do
    get "/", params: {q: SORT_TEST_TAG, search_field: "all_fields", sort: "#{Settings.FIELDS.TITLE_SORT} asc"}

    assert_response :success
    assert_includes response.body, "Alabama county boundaries"
    assert_includes response.body, "bei jing shi cheng qu jie dao tu"
    assert_operator response.body.index("Alabama county boundaries"), :<, response.body.index("bei jing shi cheng qu jie dao tu")
  end

  private

  def build_sort_test_doc(id, title)
    TitleTransliterator.add_to_document(
      fixture_doc.merge(
        "id" => id,
        "dct_title_s" => title,
        "dct_description_sm" => [SORT_TEST_TAG]
      )
    )
  end

  def fixture_doc
    @fixture_doc ||= JSON.parse(
      Rails.root.join("test/fixtures/files/gbl_documents/index-map-stanford.json").read
    )
  end
end
