# frozen_string_literal: true

require "test_helper"
require "capybara-screenshot/minitest"
require_relative "support/axe_helper"

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  [
    "headless",
    "window-size=1280x1280",
    "disable-gpu"
  ].each { |arg| options.add_argument(arg) }

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.save_path = "#{Rails.root}/tmp/screenshots"

Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include AxeHelper

  driven_by :selenium_chrome_headless
end
