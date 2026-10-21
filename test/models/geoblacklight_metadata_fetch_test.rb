# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class GeoblacklightMetadataFetchTest < ActiveSupport::TestCase
  test "metadata requests have timeouts and reuse a successful response" do
    with_metadata_response(status: 200, body: "<metadata />") do |metadata, requests, logs|
      2.times { assert_equal "<metadata />", metadata.send(:retrieve_metadata) }
      assert_equal 1, requests.size
      assert_equal 3, requests.first.request.open_timeout
      assert_equal 5, requests.first.request.timeout
      assert_equal 1, logs.size
      assert_equal 200, logs.first["status"]
      assert_nil logs.first["failure"]
    end
  end

  test "a missing response is cached per object" do
    with_metadata_response(status: 404, body: "Not found") do |metadata, requests, logs|
      2.times { assert_equal "", metadata.send(:retrieve_metadata) }
      assert_equal 1, requests.size
      assert_equal "HTTP 404", logs.first["failure"]
    end
  end

  test "a timeout is logged and is not retried by the same object" do
    with_metadata_response(error: Faraday::TimeoutError.new("slow provider")) do |metadata, requests, logs|
      2.times { assert_equal "", metadata.send(:retrieve_metadata) }
      assert_equal 1, requests.size
      assert_equal "Faraday::TimeoutError", logs.first["failure"]
      assert_equal "https://example.org/metadata.xml", logs.first["endpoint"]
      assert_operator logs.first["elapsed_seconds"], :>=, 0
    end
  end

  test "connection and SSL failures preserve the empty metadata fallback" do
    [Faraday::ConnectionFailed, OpenSSL::SSL::SSLError].each do |error_class|
      with_metadata_response(error: error_class.new("unavailable provider")) do |metadata, requests, logs|
        2.times { assert_equal "", metadata.send(:retrieve_metadata) }
        assert_equal 1, requests.size
        assert_equal error_class.name, logs.first["failure"]
      end
    end
  end

  private

  def with_metadata_response(status: nil, body: nil, error: nil)
    requests = []
    logs = []
    adapter = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/metadata.xml") do |env|
        requests << env
        raise error if error
        [status, {}, body]
      end
    end
    logger = Object.new
    logger.define_singleton_method(:info) { |message| logs << JSON.parse(message) }
    logger.define_singleton_method(:warn) { |message| logs << JSON.parse(message) }
    reference = Struct.new(:endpoint).new("https://example.org/metadata.xml")
    test_adapter = Class.new(Faraday::Adapter::Test) do
      define_method(:initialize) do |app, **_options|
        super(app, adapter, &nil)
      end
    end
    Faraday.stub(:default_adapter, test_adapter) do
      Geoblacklight.stub(:logger, logger) do
        yield Geoblacklight::Metadata::Base.new(reference), requests, logs
      end
    end
  end
end
