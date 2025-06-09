# frozen_string_literal: true

# Configure bot_challenge_page behavior
Rails.application.config.to_prepare do
  config = BotChallengePage::BotChallengePageController.bot_challenge_config

  config.enabled = !Rails.env.test? && Settings.turnstile.enabled

  # Cloudflare Turnstile keys
  config.cf_turnstile_sitekey = Settings.turnstile.sitekey
  config.cf_turnstile_secret_key = Settings.turnstile.secret

  # Render challenge in place instead of redirect
  config.redirect_for_challenge = false

  # Apply rate limiting to catalog#index (home/search page)
  config.rate_limited_locations = [
    {controller: "catalog", action: "index"}
  ]

  # Rate limiting policy: 3 attempts per 24 hours
  config.rate_limit_period = 24.hours
  config.rate_limit_count = 3

  # Exemption logic: allow facet fetches and safelisted IPs
  config.allow_exempt = lambda do |controller, _|
    (controller.is_a?(CatalogController) &&
      controller.params[:action].in?(%w[facet]) &&
      controller.request.headers["sec-fetch-dest"] == "empty") ||
      (Settings.turnstile.ip_safelist || []).map { |cidr| IPAddr.new(cidr) }.any? do |range|
        range.include?(controller.request.remote_ip)
      end
  end

  # Load Rack::Attack rules last
  BotChallengePage::BotChallengePageController.rack_attack_init
end
