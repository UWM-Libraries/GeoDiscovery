# frozen_string_literal: true

require "test_helper"

class SolrDocumentTest < ActiveSupport::TestCase
  test "prefers transliterated title for non latin leading titles" do
    document = SolrDocument.new(
      "dct_title_s" => "北京市城区街道图",
      "dct_title_transliterated_s" => "bei jing shi cheng qu jie dao tu"
    )

    assert_equal "bei jing shi cheng qu jie dao tu", document.preferred_index_title
    assert document.show_original_title_companion?
  end

  test "falls back to original title when transliteration is unavailable" do
    document = SolrDocument.new("dct_title_s" => "北京市城区街道图")

    assert_equal "北京市城区街道图", document.preferred_index_title
    assert_not document.show_original_title_companion?
  end

  test "keeps latin leading titles as the preferred index title" do
    document = SolrDocument.new(
      "dct_title_s" => "Alabama county boundaries",
      "dct_title_transliterated_s" => "alabama county boundaries"
    )

    assert_equal "Alabama county boundaries", document.preferred_index_title
    assert_not document.show_original_title_companion?
  end
end
