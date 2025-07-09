# frozen_string_literal: true

# Configure bot_challenge_page behavior
# More configuration is available; see:
# https://github.com/samvera-labs/bot_challenge_page/blob/main/app/models/bot_challenge_page/config.rb
Rails.application.config.to_prepare do
  config = BotChallengePage::BotChallengePageController.bot_challenge_config

  # If disabled, no challenges will be issued (Currently always disabled in RAILS_ENV=test)
  config.enabled = !Rails.env.test? && Settings.turnstile.enabled

  # Get from CloudFlare Turnstile: https://www.cloudflare.com/application-services/products/turnstile/
  # Some testing keys are also available: https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  #
  # This set of keys will always pass the challenge; the link above includes
  # sets that will always challenge or always fail, which is useful for local testing
  config.cf_turnstile_sitekey = Settings.turnstile.sitekey
  config.cf_turnstile_secret_key = Settings.turnstile.secret

  # Render challenge in place instead of redirect
  config.redirect_for_challenge = false

  # What paths do you want to protect?
  #
  # You can use path prefixes: "/catalog" or even "/"
  #
  # Or hashes with controller and/or action:
  #
  #   { controller: "catalog" }
  #   { controller: "catalog", action: "index" }
  #
  # Note that we can only protect GET paths, and also think about making sure you DON'T protect
  # any path your front-end needs JS `fetch` access to, as this would block it
  # Apply rate limiting to catalog#index (home/search page)
  config.rate_limited_locations = []

  # Allow rate_limit_count requests in rate_limit_period, before issuing challenge
  # This is low because some bots rotate IPs, so we want to catch them quickly
  config.rate_limit_period = 24.hours
  config.rate_limit_count = 3
  config.rate_limit_discriminator = ->(req, _) { req.ip }

  # How long will a challenge success exempt a session from further challenges? (36 is default)
  # config.session_passed_good_for = 36.hours

  # Exemption logic: allow facet fetches and safelisted IPs
  # Modified from Stanford's implementation to use .env variable for safelisting
  ip_safelist = ENV.fetch("TURNSTILE_IP_SAFELIST", "").split(",").map(&:strip)

  config.allow_exempt = lambda do |controller, _|
    exempt = controller.session[:bot_challenge_passed] ||
      (controller.is_a?(CatalogController) &&
       controller.params[:action].in?(%w[facet]) &&
       controller.request.headers["sec-fetch-dest"] == "empty") ||
      ip_safelist.map { |cidr| IPAddr.new(cidr) }.any? { |range| range.include?(controller.request.remote_ip) }

    Rails.logger.warn "[Turnstile‑EXEMPT] IP: #{controller.request.remote_ip}, Exempt: #{exempt}"
    Rails.logger.warn "[Turnstile‑SESSION] Passed: #{controller.session[:bot_challenge_passed]}"
    exempt
  end

  # This gets called last; we use rack_attack to do the rate limiting part
  BotChallengePage::BotChallengePageController.rack_attack_init
  Rails.logger.warn "[Turnstile‑INIT] throttles: #{Rack::Attack.throttles.keys.inspect}"
end
