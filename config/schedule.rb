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
every :day, at: "11:50am", roles: [:app] do
  rake "uwm:opendataharvest:harvest_dcat"
end

# Updates the UWM OpenGeoMetadata directory (git pull) and re-index
every :day, at: "11:53 am", roles: [:app] do
  command ". /var/www/rubyapps/uwm-geoblacklight/current/bin/geocombine_pull_and_index.sh"
end
