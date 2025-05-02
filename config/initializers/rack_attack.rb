class Rack::Attack
  # Throttle GET requests to /catalog per IP
  throttle("req/ip/catalog", limit: 2, period: 20.seconds) do |req|
    req.ip if req.path.start_with?("/catalog") && req.get?
  end

  # Customize the response for throttled requests
  self.throttled_response = lambda do |env|
    request = Rack::Request.new(env)
    session = request.session.to_hash
    passed = session["bot_challenge_page_passed"] || session["bot_detection-passed"]

    puts "[Rack::Attack] Throttled request from IP: #{request.ip}"
    puts "[Rack::Attack] Session: #{session.inspect}"
    puts "[Rack::Attack] Challenge passed? #{passed.inspect}"

    if passed
      # Let request through as normal
      env["rack.attack.match_type"] = nil
      Rails.application.call(env)
    else
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
end
