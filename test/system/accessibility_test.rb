# frozen_string_literal: true

require "application_system_test_case"

class AccessibilityTest < ApplicationSystemTestCase
  def test_homepage_has_no_critical_accessibility_violations
    visit("/")

    assert_no_axe_violations
  end

  def test_search_results_have_no_critical_accessibility_violations
    visit("/?q=water")

    assert_no_axe_violations
  end
end
