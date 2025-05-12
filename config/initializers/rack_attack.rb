class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  Rack::Attack.cache.store = Rails.cache

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle("req/ip", limit: 200, period: 5.minutes) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  # Set up custom logger for Rack::Attack
  RACK_ATTACK_LOGGER = Logger.new(
    Rails.root.join("log/rack_attack.log"),
    10,                         # keep 10 rotated files
    5 * 1024 * 1024             # 5 MB each
  )
  RACK_ATTACK_LOGGER.level = Logger::WARN

  RACK_ATTACK_LOGGER.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.utc.iso8601}] #{severity}: #{msg}\n"
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  self.throttled_response = lambda do |env|
    req = Rack::Request.new(env)
    cache_key = "rack::attack:logged:#{req.ip}"

    unless Rails.cache.exist?(cache_key)
      RACK_ATTACK_LOGGER.warn "Throttled IP #{req.ip} on path #{req.path}"
      Rails.cache.write(cache_key, true, expires_in: 5.minutes)
    end

    [
      503,
      {"Content-Type" => "text/plain"},
      ["Service temporarily unavailable. Please try again later.\n"]
    ]
  end
end
