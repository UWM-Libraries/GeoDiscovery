# frozen_string_literal: true

require "application_system_test_case"

class SearchResultsTest < ApplicationSystemTestCase
  def setup
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
end
