# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "uses temporal coverage when present" do
    document = SolrDocument.new(
      Settings.FIELDS.TEMPORAL_COVERAGE => ["1944 to 1994"],
      Settings.FIELDS.INDEX_YEAR => (1944..1994).to_a
    )

    result = format_index_temporal_coverage(
      document: document,
      field: Settings.FIELDS.TEMPORAL_COVERAGE,
      value: document[Settings.FIELDS.TEMPORAL_COVERAGE],
      config: nil
    )

    assert_equal "1944 to 1994", result
  end

  test "falls back to date range when temporal coverage is missing" do
    document = SolrDocument.new(
      Settings.FIELDS.DATE_RANGE => ["[1944 TO 1994]"],
      Settings.FIELDS.INDEX_YEAR => (1944..1994).to_a
    )

    result = format_index_temporal_coverage(
      document: document,
      field: Settings.FIELDS.TEMPORAL_COVERAGE,
      value: document[Settings.FIELDS.TEMPORAL_COVERAGE],
      config: nil
    )

    assert_equal "1944 to 1994", result
  end

  test "falls back to a single index year when needed" do
    document = SolrDocument.new(Settings.FIELDS.INDEX_YEAR => [2005])

    result = format_index_temporal_coverage(
      document: document,
      field: Settings.FIELDS.TEMPORAL_COVERAGE,
      value: document[Settings.FIELDS.TEMPORAL_COVERAGE],
      config: nil
    )

    assert_equal "2005", result
  end
end
