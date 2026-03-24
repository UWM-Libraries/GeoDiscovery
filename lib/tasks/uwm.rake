# frozen_string_literal: true

require "sidekiq/api"
require "timeout"

desc "Run test suite"
task :ci do
  success = true

  if ENV["SOLR_URL"].present?
    wait_for_solr!
    system "RAILS_ENV=test bundle exec rake uwm:index:seed"
    success = system 'RUBYOPT=W0 RAILS_ENV=test TESTOPTS="-v" bundle exec rails test:system test'
  else
    shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: "tmp/blacklight-core")) do |solr|
      solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        wait_for_solr!
        system "RAILS_ENV=test bundle exec rake uwm:index:seed"
        success = system 'RUBYOPT=W0 RAILS_ENV=test TESTOPTS="-v" bundle exec rails test:system test'
      end
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
  def wait_for_solr!(timeout: 30)
    Timeout.timeout(timeout) do
      loop do
        response = Blacklight.default_index.connection.get("select", params: {q: "*:*", rows: 0})
        break if response["response"]
      rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused, Errno::ECONNREFUSED
        sleep 0.25
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for Solr at #{Blacklight.default_index.connection.options[:url]}"
  end

  def transliterated_docs_from(paths)
    Dir[paths].map { |f| JSON.parse File.read(f) }.flatten.map do |document|
      TitleTransliterator.add_to_document(document)
    end
  end

  desc "Run Solr and GeoBlacklight for interactive development"
  task :server, [:rails_server_args] do
    require "solr_wrapper"

    shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8983, instance_dir: "tmp/blacklight-core")) do |solr|
      solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Solr running at http://localhost:8983/solr/blacklight-core/, ^C to exit"
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
  end

  desc "Start solr server for testing."
  task :test do
    if Rails.env.test?
      shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
      shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

      SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: "tmp/blacklight-core")) do |solr|
        solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
          puts "Solr running at http://localhost:8985/solr/#/blacklight-core/, ^C to exit"
          begin
            Rake::Task["uwm:index:seed"].invoke
            sleep
          rescue Interrupt
            puts "\nShutting down..."
          end
        end
      end
    else
      system("rake uwm:test RAILS_ENV=test")
    end
  end

  desc "Start solr server for development."
  task :development do
    shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8983, instance_dir: "tmp/blacklight-core")) do |solr|
      solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Solr running at http://localhost:8983/solr/#/blacklight-core/, ^C to exit"
        begin
          Rake::Task["uwm:index:seed"].invoke
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
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
      docs = transliterated_docs_from("test/fixtures/files/**/*.json")
      Blacklight.default_index.connection.add docs
      Blacklight.default_index.connection.commit
    end

    desc "Put uwm sample data into solr"
    task uwm: :environment do
      docs = transliterated_docs_from("test/fixtures/files/uwm_documents/*.json")
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
