Rails.application.config.to_prepare do
  # Enable the bot challenge system:
  BotChallengePage::BotChallengePageController.bot_challenge_config.enabled = true

  # Set turnstile keys:
  BotChallengePage::BotChallengePageController.bot_challenge_config.cf_turnstile_sitekey = ENV["TURNSTILE_SITE_KEY"]
  BotChallengePage::BotChallengePageController.bot_challenge_config.cf_turnstile_secret_key = ENV["TURNSTILE_SECRET_KEY"]
  
  # Bot challenge configuration:
  BotChallengePage::BotChallengePageController.bot_challenge_config.redirect_for_challenge = true

  # We're using Rack::Attack for rate-limiting, so the gem's built-in rate limit settings are unused:
  # BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limited_locations = []
  # BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limit_period = 12.hours
  # BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limit_count = 2
end
