# config/initializers/rack_attack.rb

Rails.logger.warn "[Rack::Attack] Initializer file loaded"

class Rack::Attack
  # Ensure Rack::Attack uses the same cache as Rails (Redis)
  Rack::Attack.cache.store = Rails.cache

  # Throttle: Catalog hammering (2 requests every 20 seconds per IP)
  throttle("req/ip/search_q", limit: 2, period: 20.seconds) do |req|
    if req.get? && req.params["q"].present?
      Rails.logger.info "[Rack::Attack] Search throttle triggered for #{req.ip} (q=#{req.params['q']})"
      req.ip
    end
  end

  # Custom throttled response: redirect to bot challenge
  self.throttled_responder = lambda do |request|
    Rails.logger.warn "[Rack::Attack] Throttled IP #{request.ip} on #{request.path}"
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
