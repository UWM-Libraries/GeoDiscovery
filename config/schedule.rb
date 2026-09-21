# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Explicitly set path to 'current' to avoid hardcoding to timestamped release
set :path, "/var/www/rubyapps/uwm-geoblacklight/current"

# Daily maintenance jobs

# Cleans up anonymous user accounts created by search sessions
every :day, at: "1:30am", roles: [:app] do
  rake "devise_guests:delete_old_guest_users[2]"
end

# Cleans up recent anonymous search records
every :day, at: "2:00am", roles: [:app] do
  rake "blacklight:delete_old_searches[7]"
end

# Weekly maintenance jobs

# Allmaps jobs are disabled while Blacklight Allmaps lacks GeoBlacklight 5 /
# Blacklight 8 compatibility. Restore the harvest, facet refresh, and orphan
# purge schedules when that integration is reintroduced.

# Updates OpenGeoMetadata, harvests DCAT, converts legacy records, normalizes harvested Aardvark,
# and re-indexes into Solr.
every :wednesday, at: "4:00am", roles: [:app] do
  rake "uwm:geocombine_pull_and_index"
end

# Build the sitemap the day after the weekly metadata refresh.
every :thursday, at: "4:00am", roles: [:app] do
  rake "sitemap:refresh"
end

# Monthly maintenance jobs

# Thumbnail sidecar jobs are disabled while geoblacklight_sidecar_images lacks
# GeoBlacklight 5 compatibility. Restore retry and orphan-purge schedules when
# the integration is reintroduced.
