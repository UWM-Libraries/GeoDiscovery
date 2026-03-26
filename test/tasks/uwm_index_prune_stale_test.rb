# frozen_string_literal: true

require "test_helper"
require "rake"
require "solr_wrapper"

class UwmIndexPruneStaleTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task["uwm:index:prune_stale"]
    @task.reenable
  end

  test "prune_stale removes records absent from the current harvest set" do
    shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    harvested_doc = JSON.parse(
      File.read(Rails.root.join("lib/opendataharvest/src/opendataharvest/data/agsl-opendata-harvest.json"))
    )
    stale_doc = harvested_doc.merge(
      "id" => "stale-opendataharvest-record",
      "dct_title_s" => "Stale opendataharvest record"
    )

    SolrWrapper.wrap(shared_solr_opts.merge(port: 8985, instance_dir: "tmp/blacklight-core")) do |solr_wrapper|
      solr_wrapper.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        solr = RSolr.connect(url: "http://127.0.0.1:8985/solr/blacklight-core")
        solr.add([harvested_doc, stale_doc])
        solr.commit

        repository = Blacklight.default_index
        original_connection = repository.connection
        repository.define_singleton_method(:connection) { solr }

        begin
          capture_io { @task.invoke }
        ensure
          repository.define_singleton_method(:connection) { original_connection }
        end

        ids = solr.get(
          "select",
          params: {q: "*:*", fl: "id", rows: 10_000, sort: "id asc"}
        ).dig("response", "docs").map { |doc| doc.fetch("id") }

        assert_includes ids, "agsl-opendata-harvest"
        refute_includes ids, "stale-opendataharvest-record"
      end
    end
  ensure
    @task.reenable
  end
end
