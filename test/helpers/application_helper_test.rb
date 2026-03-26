# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "render_html_value preserves line breaks between multiple values" do
    result = render_html_value(value: ["First paragraph.", "Second paragraph."])

    assert_includes result, "<p>First paragraph.</p>"
    assert_includes result, "<p>Second paragraph.</p>"
  end

  test "truncate_render_html_value wraps rendered content for expansion controls" do
    result = truncate_render_html_value(value: ["Long rights statement."])

    assert_includes result, 'class="truncate-abstract"'
    assert_includes result, "<p>Long rights statement.</p>"
  end

  test "show fields use the truncating html helper for description and rights" do
    description_field = CatalogController.blacklight_config.show_fields[Settings.FIELDS.DESCRIPTION]
    rights_field = CatalogController.blacklight_config.show_fields[Settings.FIELDS.RIGHTS]

    assert_equal :truncate_render_html_value, description_field.helper_method
    assert_equal :truncate_render_html_value, rights_field.helper_method
  end

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
