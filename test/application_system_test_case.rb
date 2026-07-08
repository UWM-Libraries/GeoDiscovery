# frozen_string_literal: true

require "test_helper"
require "capybara-screenshot/minitest"
require_relative "support/axe_helper"

Selenium::WebDriver.logger.level = :warn

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.page_load_strategy = "eager"

  [
    "headless=new",
    "window-size=1280,1280",
    "disable-gpu",
    "disable-dev-shm-usage",
    "no-sandbox"
  ].each { |arg| options.add_argument(arg) }

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.open_timeout = 120
  http_client.read_timeout = 120

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:, http_client:)
end

Capybara.save_path = "#{Rails.root}/tmp/screenshots"

Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include AxeHelper

  driven_by :selenium_chrome_headless
end
