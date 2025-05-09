require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    Rack::Attack.enabled = true
    Rack::Attack.reset!

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.throttle("test/req/ip", limit: 3, period: 60) { |req| req.ip }

    Rack::Attack.throttled_responder = lambda do |_request|
      [
        503,
        {"Content-Type" => "text/plain"},
        ["Service temporarily unavailable. Please try again later.\n"]
      ]
    end
  end

  teardown do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  test "blocks request after exceeding limit" do
    3.times do
      get "/robots.txt", headers: {"REMOTE_ADDR" => "1.2.3.4"}
      assert_response :success
    end

    get "/robots.txt", headers: {"REMOTE_ADDR" => "1.2.3.4"}
    assert_response :service_unavailable
    assert_match(/Service temporarily unavailable/, response.body)
  end
end
