# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Harvest thumbnail images for search results
every :day, at: "12:05am", roles: [:app] do
  rake "gblsci:images:harvest_retry"
end

# Build the sitemap
every :day, at: "12:30am", roles: [:app] do
  rake "sitemap:refresh"
end

# Cleans up anonymous user accounts created by search sessions
every :day, at: "1:30am", roles: [:app] do
  rake "devise_guests:delete_old_guest_users[2]"
end

# Cleans up recent anonymous search records
every :day, at: "2:30am", roles: [:app] do
  rake "blacklight:delete_old_searches[7]"
end

# Runs the OpenDataHarvest DCAT script
every :monday, at: "3:30am", roles: [:app] do
  rake "uwm:opendataharvest"
end

# Updates the UWM OpenGeoMetadata directory (git pull) and re-index
every :monday, at: "4:00 am", roles: [:app] do
  # Ours
  rake "geocombine:pull[edu.uwm]"
  # Direct from GeoCombine
  rake "geocombine:pull[edu.uchicago]"
  rake "geocombine:pull[edu.illinois]"
  rake "geocombine:pull[edu.indiana]"
  rake "geocombine:pull[edu.uiowa]"
  rake "geocombine:pull[edu.umd]"
  rake "geocombine:pull[edu.msu]"
  rake "geocombine:pull[edu.umn]"
  rake "geocombine:pull[edu.unl]"
  rake "geocombine:pull[edu.nyu]"
  rake "geocombine:pull[edu.osu]"
  rake "geocombine:pull[edu.psu]"
  rake "geocombine:pull[edu.purdue]"
  rake "geocombine:pull[edu.rutgers]"
  rake "geocombine:pull[edu.umich]"
  # Metadata We've Converted
  rake "geocombine:pull[edu.wisc.aardvark]"
  rake "geocombine:pull[edu.uwm.converted]"
  # Index
  rake "geocombine:index"
end
