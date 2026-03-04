# frozen_string_literal: true

require "application_system_test_case"

class HomepageTest < ApplicationSystemTestCase
  def setup
    visit("/")
  end

  def test_basic_dom
    assert page.has_selector?("nav")                    # Navigation
    assert page.has_selector?("main")                   # Main
    assert page.has_selector?("form.search-query-form") # Search Form
    assert page.has_selector?("a.advanced_search")      # Adv Search Link
    assert page.has_selector?("div#map")                # Map
  end

  def test_homepage_search
    within("form.search-query-form") do
      fill_in("q", with: "water")
      click_button "Search"
    end

    assert page.has_content?("Search Results")
  end

  # def test_map_geosearch
  #   assert page.has_selector?("div.geosearch")
  # end

  def test_google_analytics
    assert page.source.scan(/<!-- Google tag (gtag.js) -->/m)
  end
end
