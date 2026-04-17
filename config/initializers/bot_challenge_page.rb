# frozen_string_literal: true

# Configure bot_challenge_page behavior
# More configuration is available in the gem's Config class and README.
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

  # How long will a challenge success exempt a session from further challenges? (36 is default)
  # config.session_passed_good_for = 36.hours

  # Exemption logic: allow facet fetches and safelisted IPs.
  # In bot_challenge_page 1.x this is configured with skip_when, which runs in
  # the controller instance context.
  ip_safelist =
    Array(Settings.turnstile.ip_safelist).map(&:to_s) +
    ENV.fetch("TURNSTILE_IP_SAFELIST", "").split(",").map(&:strip)
  safelisted_ranges = ip_safelist.filter_map do |cidr|
    IPAddr.new(cidr)
  rescue IPAddr::InvalidAddressError
    nil
  end

  config.skip_when = lambda do |_config|
    safelisted_ranges.any? { |range| range.include?(request.remote_ip) }
  end

  # Disable Rack::Attack — this will prevent the additional rate-limiting logic from being applied
  # BotChallengePage::BotChallengePageController.rack_attack_init
  # Rails.logger.warn "[Turnstile‑INIT] throttles: #{Rack::Attack.throttles.keys.inspect}"
end
