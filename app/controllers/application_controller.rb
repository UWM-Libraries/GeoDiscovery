# frozen_string_literal: true

# See config/initializers/bot_challenge_page.rb to control this behavior
class ApplicationController < ActionController::Base
  before_action do |controller|
    BotChallengePage::BotChallengePageController.bot_challenge_enforce_filter(controller)
  end

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  before_action :allow_geoblacklight_params

  def allow_geoblacklight_params
    # Blacklight::Parameters will pass these to params.permit
    blacklight_config.search_state_fields.append(Settings.GBL_PARAMS)
  end
end
