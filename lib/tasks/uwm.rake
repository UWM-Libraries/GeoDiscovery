# frozen_string_literal: true

require "sidekiq/api"
require "set"

desc "Run test suite"
task :ci do
  shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
  shared_solr_opts[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

  success = true
  SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: "tmp/blacklight-core")) do |solr|
    solr.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
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
  def harvested_document_ids
    GeoCombine::Harvester.new.docs_to_index.each_with_object(Set.new) do |(doc, _path), ids|
      ids << doc.fetch(SolrDocument.unique_key)
    end
  end

  def indexed_document_ids(solr:, unique_key:)
    ids = Set.new
    cursor_mark = "*"

    loop do
      response = solr.get(
        "select",
        params: {
          q: "*:*",
          fl: unique_key,
          cursorMark: cursor_mark,
          rows: 1000,
          sort: "#{unique_key} asc"
        }
      )

      response.dig("response", "docs").each do |doc|
        ids << doc.fetch(unique_key)
      end

      break if response["nextCursorMark"] == cursor_mark

      cursor_mark = response["nextCursorMark"]
    end

    ids
  end

  def transliterated_docs_from(paths)
    Dir[paths].map { |f| JSON.parse File.read(f) }.flatten.map do |document|
      TitleTransliterator.add_to_document(document)
    end
  end

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

  def wait_for_solr!(timeout: ENV.fetch("SOLR_WAIT_TIMEOUT", 90).to_i, solr_url: ENV["SOLR_URL"] || Blacklight.default_index.connection.options[:url])
    solr = RSolr.connect(url: solr_url)

    Timeout.timeout(timeout) do
      loop do
        response = solr.get("select", params: {q: "*:*", rows: 0, sort: "id asc", wt: "json"})
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

    desc "Delete Solr records no longer present in the current GeoCombine harvest set"
    task prune_stale: :environment do
      solr = Blacklight.default_index.connection
      unique_key = SolrDocument.unique_key
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "false"))

      harvested_ids = harvested_document_ids
      indexed_ids = indexed_document_ids(solr:, unique_key:)
      stale_ids = indexed_ids - harvested_ids

      puts "Harvested IDs: #{harvested_ids.size}"
      puts "Indexed IDs: #{indexed_ids.size}"
      puts "Stale IDs: #{stale_ids.size}"

      if stale_ids.empty?
        puts "No stale Solr records found."
        next
      end

      stale_ids.to_a.sort.first(20).each do |id|
        puts "STALE #{id}"
      end
      puts "...and #{stale_ids.size - 20} more" if stale_ids.size > 20

      if dry_run
        puts "Dry run only. Re-run without DRY_RUN=true to delete these Solr records."
        next
      end

      stale_ids.each_slice(100) do |slice|
        solr.delete_by_id(slice)
      end
      solr.commit

      puts "Deleted #{stale_ids.size} stale Solr records."
      puts "You can now purge orphaned thumbnail/allmaps sidecars safely."
    end
  end

  namespace :sidecars do
    desc "Destroy orphaned Blacklight Allmaps sidecars whose Solr document no longer exists"
    task purge_allmaps_orphans: :environment do
      destroyed = 0

      Blacklight::Allmaps::Sidecar.find_each do |sidecar|
        SolrDocument.find(sidecar.solr_document_id)
      rescue StandardError
        sidecar.destroy
        destroyed += 1
        puts "orphaned / #{sidecar.solr_document_id} / destroyed"
      end

      puts "Destroyed #{destroyed} orphaned Allmaps sidecars."
    end
  end
end
