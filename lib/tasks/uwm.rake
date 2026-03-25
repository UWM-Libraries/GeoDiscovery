# frozen_string_literal: true

require "sidekiq/api"
require "timeout"

SOLR_COLLECTION = "blacklight-core"
DEVELOPMENT_SOLR_PORT = 8983
TEST_SOLR_PORT = 8985

desc "Run test suite"
task :ci do
  success = true

  if ENV["USE_EXISTING_SOLR"].present?
    wait_for_solr!
    system "RAILS_ENV=test bundle exec rake uwm:index:seed"
    success = system 'RUBYOPT=W0 RAILS_ENV=test TESTOPTS="-v" bundle exec rails test:system test'
  else
    with_managed_solr(port: TEST_SOLR_PORT) do
      system "RAILS_ENV=test bundle exec rake uwm:index:seed"
      success = system 'RUBYOPT=W0 RAILS_ENV=test TESTOPTS="-v" bundle exec rails test:system test'
    end
  end

  exit!(1) unless success
end

namespace :sidekiq do
  desc "Clear all Sidekiq queues"
  task clear_all: :environment do
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::RetrySet.new.clear
    puts "All Sidekiq queues, scheduled jobs, and retries have been cleared."
  end
end

namespace :redis do
  desc "Clear all Redis cache"
  task clear_cache: :environment do
    redis = Redis.new
    redis.flushdb
    puts "Redis cache has been cleared."
  end
end

namespace :uwm do
  def shared_solr_opts
    opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]
    opts
  end

  def with_managed_solr(port:)
    SolrWrapper.wrap(shared_solr_opts.merge(port: port, instance_dir: "tmp/blacklight-core")) do |solr|
      wait_for_solr_wrapper!(solr)
      solr.with_collection(name: SOLR_COLLECTION, dir: Rails.root.join("solr", "conf").to_s) do
        wait_for_solr!
        yield
      end
    end
  end

  def wait_for_solr_wrapper!(solr, timeout: ENV.fetch("SOLR_WRAPPER_WAIT_TIMEOUT", 90).to_i)
    Timeout.timeout(timeout) do
      loop do
        break if solr.started?
        sleep 0.25
      end
    end
  rescue Timeout::Error
    raise "Timed out starting managed Solr on port #{solr.port}"
  end

  def wait_for_solr!(timeout: ENV.fetch("SOLR_WAIT_TIMEOUT", 90).to_i)
    solr_url = Blacklight.default_index.connection.options[:url]
    solr = RSolr.connect(url: solr_url)

    Timeout.timeout(timeout) do
      loop do
        response = solr.get("select", params: {q: "*:*", rows: 0, sort: "id asc", wt: "ruby"})
        break if response.dig("responseHeader", "status") == 0
      rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused, Errno::ECONNREFUSED, Faraday::ConnectionFailed
        sleep 0.25
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for Solr at #{solr_url}"
  end
  desc "Run Solr and GeoBlacklight for interactive development"
  task :server, [:rails_server_args] do
    require "solr_wrapper"

    with_managed_solr(port: DEVELOPMENT_SOLR_PORT) do
      puts "Solr running at http://localhost:#{DEVELOPMENT_SOLR_PORT}/solr/#{SOLR_COLLECTION}/, ^C to exit"
      puts " "
      begin
        Rake::Task["uwm:index:seed"].invoke
        system "bundle exec rails s -b 0.0.0.0"
        sleep
      rescue Interrupt
        puts "\nShutting down..."
      end
    end
  end

  desc "Start solr server for testing."
  task :test do
    if Rails.env.test?
      with_managed_solr(port: TEST_SOLR_PORT) do
        puts "Solr running at http://localhost:#{TEST_SOLR_PORT}/solr/#{SOLR_COLLECTION}/, ^C to exit"
        begin
          Rake::Task["uwm:index:seed"].invoke
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    else
      system("rake uwm:test RAILS_ENV=test")
    end
  end

  desc "Start solr server for development."
  task :development do
    with_managed_solr(port: DEVELOPMENT_SOLR_PORT) do
      puts "Solr running at http://localhost:#{DEVELOPMENT_SOLR_PORT}/solr/#{SOLR_COLLECTION}/, ^C to exit"
      begin
        Rake::Task["uwm:index:seed"].invoke
        sleep
      rescue Interrupt
        puts "\nShutting down..."
      end
    end
  end

  namespace :opendataharvest do
    desc "Set up Python venv environment for opendataharvest"
    task :setup_python_env do
      sh "lib/opendataharvest/src/setup_python_env.sh"
    end

    desc "Run the DCAT_Harvester.py Python script"
    task :harvest_dcat do
      sh "lib/opendataharvest/venv/bin/python3 lib/opendataharvest/src/opendataharvest/DCAT_Harvester.py"
    end

    desc "Run the conversion scripts on GBL 1.0 metadata institutions"
    task :gbl1_to_aardvark do
      puts "Running GeoBlacklight 1.0 to OGM Aardvark Metadata Conversion.\nsee gbl_to_aardvark.log"
      sh "lib/opendataharvest/venv/bin/python3 lib/opendataharvest/src/opendataharvest/gbl_to_aardvark.py"
      puts "Run rake geocombine:index to index converted documents"
    end
  end

  namespace :index do
    desc "Put all sample data into solr"
    task seed: :environment do
      docs = Dir["test/fixtures/files/**/*.json"].map { |f| JSON.parse File.read(f) }.flatten
      Blacklight.default_index.connection.add docs
      Blacklight.default_index.connection.commit
    end

    desc "Put uwm sample data into solr"
    task uwm: :environment do
      docs = Dir["test/fixtures/files/uwm_documents/*.json"].map { |f| JSON.parse File.read(f) }.flatten
      Blacklight.default_index.connection.add docs
      Blacklight.default_index.connection.commit
    end

    desc "Delete all sample data from solr"
    task delete_all: :environment do
      Blacklight.default_index.connection.delete_by_query "*:*"
      Blacklight.default_index.connection.commit
    end
  end
end
