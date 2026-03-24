# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("ACTION_MAILER_FROM", %("AGSL GeoDiscovery" <noreply@uwm.edu>))
  layout "mailer"
end
