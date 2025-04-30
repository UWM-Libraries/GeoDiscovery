require 'net/http'
require 'json'

class TurnstileVerifier
  def initialize(response_token, remote_ip)
    @response_token = response_token
    @remote_ip = remote_ip
  end

  def success?
    return false unless @response_token.present?

    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(uri, {
      "secret" => ENV['TURNSTILE_SECRET_KEY'],
      "response" => @response_token,
      "remoteip" => @remote_ip
    })

    json = JSON.parse(response.body)
    json["success"] == true
  rescue => e
    Rails.logger.error("Turnstile verification failed: #{e.message}")
    false
  end
end
