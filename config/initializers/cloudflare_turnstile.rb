# frozen_string_literal: true

RailsCloudflareTurnstile.configure do |c|
  c.enabled = !Rails.env.test?
  c.site_key = ENV["TURNSTILE_SITE_KEY"]
  c.secret_key = ENV["TURNSTILE_SECRET_KEY"]
  c.fail_open = true
end
