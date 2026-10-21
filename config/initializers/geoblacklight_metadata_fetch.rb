# frozen_string_literal: true

# Local GeoBlacklight 4.7 customization: keep slow metadata providers from
# occupying Passenger workers indefinitely, and fetch once per metadata object.
Rails.application.config.to_prepare do
  Geoblacklight::Metadata::Base.class_eval do
    private

    def retrieve_metadata
      return @retrieved_metadata if instance_variable_defined?(:@retrieved_metadata)

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      connection = Faraday.new(url: @reference.endpoint) do |conn|
        conn.use Geoblacklight::FaradayMiddleware::FollowRedirects
        conn.options.open_timeout = 3
        conn.options.timeout = 5
        conn.adapter Faraday.default_adapter
      end
      response = connection.get
      failure = "HTTP 404" if response&.status == 404
      failure = "No response" if response.nil?
      @retrieved_metadata = failure ? "" : response.body.to_s
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, OpenSSL::SSL::SSLError => error
      failure = error.class.name
      @retrieved_metadata = ""
    ensure
      if started_at
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
        details = {
          event: "metadata_fetch",
          endpoint: @reference.endpoint,
          elapsed_seconds: elapsed.round(3),
          status: response&.status,
          failure: failure
        }
        Geoblacklight.logger.public_send(failure ? :warn : :info, details.to_json)
      end
    end
  end
end
