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

# Harvest thumbnail images for search results.
every :sunday, at: "1:00am", roles: [:app] do
  rake "gblsci:images:harvest_retry"
end

# Harvest Allmaps IIIF annotation data.
every :sunday, at: "3:00am", roles: [:app] do
  rake "blacklight_allmaps:sidecars:harvest:allmaps"
end

# Refresh the georeferenced facet after the Sunday Allmaps harvest window.
every :sunday, at: "7:00am", roles: [:app] do
  rake "blacklight_allmaps:index:georeferenced_facet"
end

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

# Purge thumbnail orphans monthly on the second Monday at 4:00AM.
every "0 4 8-14 * 1", roles: [:app] do
  rake "gblsci:images:harvest_purge_orphans"
end

# Purge Allmaps sidecar orphans monthly on the third Tuesday at 4:00AM.
every "0 4 15-21 * 2", roles: [:app] do
  rake "blacklight_allmaps:sidecars:purge_orphans"
end
