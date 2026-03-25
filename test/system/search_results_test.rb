# frozen_string_literal: true

require "application_system_test_case"
require "stringio"

class SearchResultsTest < ApplicationSystemTestCase
  def setup
    attach_tall_thumbnail_to_first_water_result
    visit("/?q=water")
  end

  def test_basic_dom
    assert page.has_selector?("nav")                    # Navigation
    assert page.has_selector?("main")                   # Main
    assert page.has_selector?("form.search-query-form") # Search Form
    assert page.has_selector?("a.advanced_search")      # Adv Search Link
    assert page.has_selector?("div#map")                # Map
    assert page.has_selector?("div#documents")          # Search Results
  end

  def test_result_dom
    within("#documents") do
      assert page.has_selector?("article.document")       # Search Result
      assert page.has_selector?("article.document")       # Search Result
      assert page.has_selector?("div.thumbnail")          # Thumbnail
      assert page.has_selector?("h3.index_title")         # Title
      assert page.has_selector?("span.document-counter")  # Doc Counter
      assert page.has_selector?("div.status-icons")       # Status Icons
    end
  end

  def test_thumbnail_images_stay_within_their_container
    assert page.has_selector?("#documents .thumbnail img", visible: :all)

    bounds = page.evaluate_script(<<~JS)
      (() => {
        const thumbnail = document.querySelector("#documents .thumbnail");
        const image = thumbnail.querySelector("img");

        if (!image.complete) {
          return null;
        }

        const thumbnailRect = thumbnail.getBoundingClientRect();
        const imageRect = image.getBoundingClientRect();

        return {
          top_delta: imageRect.top - thumbnailRect.top,
          right_delta: thumbnailRect.right - imageRect.right,
          bottom_delta: thumbnailRect.bottom - imageRect.bottom,
          left_delta: imageRect.left - thumbnailRect.left
        };
      })()
    JS

    refute_nil bounds
    assert_operator bounds["top_delta"], :>=, -1
    assert_operator bounds["right_delta"], :>=, -1
    assert_operator bounds["bottom_delta"], :>=, -1
    assert_operator bounds["left_delta"], :>=, -1
  end

  private

  def attach_tall_thumbnail_to_first_water_result
    response = Blacklight.default_index.connection.get(
      "select",
      params: {q: "water", rows: 1, fl: "id,_version_", wt: "ruby"}
    )
    source = response.dig("response", "docs", 0)
    return unless source

    document = SolrDocument.new(source)
    document.sidecar.image.attach(
      io: StringIO.new(tall_thumbnail_svg),
      filename: "thumbnail.svg",
      content_type: "image/svg+xml"
    )
  end

  def tall_thumbnail_svg
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="160" viewBox="0 0 100 160">
        <rect width="100" height="160" fill="#ffbd00"/>
        <rect x="12" y="12" width="76" height="136" fill="#000000"/>
      </svg>
    SVG
  end
end
