class Rack::Attack
  # Throttle GET requests to /catalog per IP, unless bot challenge was passed
  throttle("req/ip/catalog", limit: 2, period: 20.seconds) do |req|
    session = req.env["rack.session"]
    passed = session && (session["bot_challenge_page_passed"] || session["bot_detection-passed"])

    unless passed
      req.ip if req.path.start_with?("/catalog") && req.get?
    end
  end

  # Customize the response for throttled requests
  self.throttled_response = lambda do |env|
    request = Rack::Request.new(env)
    session = env["rack.session"]
    passed = session && (session["bot_challenge_page_passed"] || session["bot_detection-passed"])

    if Rails.env.development? || Rails.env.test?
      Rails.logger.debug { "[Rack::Attack] Throttled request from IP: #{request.ip}" }
      Rails.logger.debug { "[Rack::Attack] Session: #{session.inspect}" }
      Rails.logger.debug { "[Rack::Attack] Challenge passed? #{passed.inspect}" }
    end

    # Redirect to bot challenge page
    dest = request.fullpath
    [
      302,
      {
        "Location" => "/challenge?dest=#{Rack::Utils.escape(dest)}",
        "Content-Type" => "text/html",
        "Content-Length" => "0"
      },
      []
    ]
  end
end
