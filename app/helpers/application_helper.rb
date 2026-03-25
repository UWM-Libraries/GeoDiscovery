# frozen_string_literal: true

module ApplicationHelper
  def render_html_value(args)
    simple_format(Array(args[:value]).flatten.join(" "))
  end

  def truncate_render_html_value(args)
    tag.div class: "truncate-abstract" do
      render_html_value(args)
    end
  end

  def format_index_temporal_coverage(args)
    temporal_coverage = Array(args[:value]).reject(&:blank?)
    return temporal_coverage.to_sentence if temporal_coverage.present?

    date_range = Array(args[:document][Settings.FIELDS.DATE_RANGE]).first
    parsed_date_range = parse_solr_year_range(date_range)
    return parsed_date_range if parsed_date_range.present?

    years = Array(args[:document][Settings.FIELDS.INDEX_YEAR]).filter_map { |value| Integer(value, exception: false) }.uniq.sort
    return years.first.to_s if years.one?
    return "#{years.first} to #{years.last}" if years.many?

    ""
  end

  private

  def parse_solr_year_range(value)
    return if value.blank?

    match = value.match(/\A\[(\d{4}) TO (\d{4})\]\z/)
    return unless match

    start_year, end_year = match.captures
    (start_year == end_year) ? start_year : "#{start_year} to #{end_year}"
  end
end
