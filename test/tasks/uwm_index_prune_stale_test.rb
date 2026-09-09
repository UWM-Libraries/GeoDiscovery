# frozen_string_literal: true

require "test_helper"
require "rake"
require "solr_wrapper"
require "json"
require "tmpdir"

class UwmIndexPruneStaleTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["uwm:index:prune_stale"]
    @task.reenable
  end

  test "prune_stale removes records absent from the current harvest set" do
    original_env = ENV.to_h.slice("OGM_PATH", "SCHEMA_VERSION", "DRY_RUN")
    Dir.mktmpdir("prune-stale-harvest") do |dir|
      ENV["OGM_PATH"] = dir
      ENV["SCHEMA_VERSION"] = "Aardvark"
      ENV["DRY_RUN"] = "false"
      fixture = Rails.root.join("test/fixtures/files/gbl_documents/actual-point1.json")
      File.write(File.join(dir, "harvested.json"), File.read(fixture))

      harvested_doc = GeoCombine::Harvester.new.docs_to_index.first.first
      harvested_doc_id = harvested_doc.fetch("id")
      stale_doc = harvested_doc.merge(
        "id" => "stale-opendataharvest-record",
        "dct_title_s" => "Stale opendataharvest record"
      )

      with_test_solr do |solr|
        solr.add([harvested_doc, stale_doc])
        solr.commit

        repository = Blacklight.default_index
        original_connection = repository.method(:connection)
        repository.define_singleton_method(:connection) { solr }
        begin
          capture_io { @task.invoke }
        ensure
          repository.define_singleton_method(:connection, original_connection)
        end

        ids = solr.get(
          "select",
          params: {q: "*:*", fl: "id", rows: 10_000, sort: "id asc"}
        ).dig("response", "docs").map { |doc| doc.fetch("id") }

        assert_includes ids, harvested_doc_id
        refute_includes ids, "stale-opendataharvest-record"
      end
    end
  ensure
    %w[OGM_PATH SCHEMA_VERSION DRY_RUN].each { |name| ENV[name] = original_env[name] }
    @task.reenable
  end

  private

  def with_test_solr
    previous_modules = ENV["SOLR_MODULES"]
    ENV["SOLR_MODULES"] = [previous_modules, "analysis-extras"].compact.join(",").split(",").uniq.join(",")
    options = {managed: true, verbose: true, persist: false, download_dir: "tmp",
               port: 8986, instance_dir: "tmp/blacklight-core-prune-stale-test"}
    options[:version] = ENV["SOLR_VERSION"] if ENV["SOLR_VERSION"]

    # This test deletes documents: never reuse the application's configured core.
    SolrWrapper.wrap(options) do |solr_wrapper|
      solr_wrapper.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        yield RSolr.connect(url: "http://127.0.0.1:8986/solr/blacklight-core")
      end
    end
  ensure
    ENV["SOLR_MODULES"] = previous_modules
  end
end
