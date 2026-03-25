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

  def test_show_page_download_button_has_dark_text
    visit("/catalog/stanford-cz128vq0535")

    assert page.has_selector?("#downloads-button")

    styles = page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector("#downloads-button");
        const computed = window.getComputedStyle(button);

        return {
          color: computed.color,
          background_color: computed.backgroundColor
        };
      })()
    JS

    assert_equal "rgb(0, 0, 0)", styles["color"]
    assert_equal "rgb(255, 189, 0)", styles["background_color"]
  end
end
