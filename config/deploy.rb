# frozen_string_literal: true

require "stringio"
require "whenever/capistrano"


# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "geodiscovery"
set :repo_url, "git@github.com:UWM-Libraries/GeoDiscovery.git"

# Default branch is :main
# Prompt to choose a tag (or name a branch), default to last listed tag
# unless an environment variable was passed on the command line as in:
# $ GEOBLACKLIGHT_RELEASE=1.0.0 bundle exec cap development deploy
unless ARGV.include?("deploy:rollback")
  avail_tags = `git ls-remote --sort=version:refname --refs --tags git@github.com:UWM-Libraries/GeoDiscovery.git | cut -d/ -f3-`
  set :branch,
    (ENV["GEOBLACKLIGHT_RELEASE"] || ask("release tag or branch:\n #{avail_tags}", avail_tags.chomp.split("\n").last))
end

# Ruby Version
set :ruby_version, "3.2.1"

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/rubyapps/uwm-geoblacklight"

set :migration_role, :app

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/blacklight.yml", "config/database.yml", "config/master.key", ".env.production"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor",
  "storage"

# tmp directory is user-specific
set :tmp_dir, "/home/geoblacklight/tmp/"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :deploy do
  after :updated, :compile_assets
end

namespace :deploy do
  # Hook to run the Python environment setup after deployment is finished
  after :finished, :setup_python_env do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "uwm:opendataharvest:setup_python_env"
        end
      end
    end
  end
end

# Ensure crontab is managed cleanly with Whenever
set :whenever_roles, [:app]
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

before "deploy:updated", "whenever:clear_crontab"
after "deploy:updated", "whenever:update_crontab"
