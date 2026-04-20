# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Explicitly set path to 'current' to avoid hardcoding to timestamped release
set :path, "/var/www/rubyapps/uwm-geoblacklight/current"

# Harvest thumbnail images for search results
every :sunday, at: "1:00am", roles: [:app] do
  rake "gblsci:images:harvest_retry"
end

# Build the sitemap
every :day, at: "4:30am", roles: [:app] do
  rake "sitemap:refresh"
end

# Cleans up anonymous user accounts created by search sessions
every :day, at: "1:30am", roles: [:app] do
  rake "devise_guests:delete_old_guest_users[2]"
end

# Cleans up recent anonymous search records
every :day, at: "2:00am", roles: [:app] do
  rake "blacklight:delete_old_searches[7]"
end

# Updates OpenGeoMetadata, harvests DCAT, converts legacy records, normalizes harvested Aardvark,
# and re-indexes into Solr
every :wednesday, at: "6:00am", roles: [:app] do
  rake "uwm:geocombine_pull_and_index"
end

# Harvest Allmaps IIIF Annotation Data
every :sunday, at: "3:00am", roles: [:app] do
  rake "blacklight_allmaps:sidecars:harvest:allmaps"
end

every :sunday, at: "6:30am", roles: [:app] do
  rake "blacklight_allmaps:index:georeferenced_facet"
end

# Run uwm:index:delete_all on the 15th of every month (3:00AM)
# every "0 3 15 * *", roles: [:app] do
#   rake "uwm:index:delete_all"
#   command "export RAILS_ENV='production' && export OGM_PATH='/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/' && bundle exec rake geocombine:index"
# end
