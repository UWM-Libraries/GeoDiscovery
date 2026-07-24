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
    harvested_doc = GeoCombine::Harvester.new.docs_to_index.first.first
    harvested_doc_id = harvested_doc.fetch("id")
    stale_doc = harvested_doc.merge(
      "id" => "stale-opendataharvest-record",
      "dct_title_s" => "Stale opendataharvest record"
    )

    with_test_solr do |solr|
      original_docs = solr.get(
        "select",
        params: {q: "*:*", rows: 10_000, sort: "id asc"}
      ).dig("response", "docs").map do |doc|
        doc.except("_version_", "score")
      end

      begin
        solr.delete_by_query("*:*")
        solr.commit
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

        assert_includes ids, harvested_doc_id
        refute_includes ids, "stale-opendataharvest-record"
      ensure
        solr.delete_by_query("*:*")
        solr.add(original_docs) unless original_docs.empty?
        solr.commit
      end
    end
  ensure
    @task.reenable
  end

  private

  def with_test_solr
    if ENV["SOLR_URL"]
      existing_solr = RSolr.connect(url: ENV.fetch("SOLR_URL"))
      begin
        existing_solr.get("admin/ping")
        yield existing_solr
        return
      rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused, Faraday::ConnectionFailed
        # Start an isolated Solr instance when the configured test URL is not live.
      end
    end

    shared_solr_opts = {managed: true, verbose: true, persist: false, download_dir: "tmp"}
    SolrWrapper.wrap(
      shared_solr_opts.merge(port: 8985, instance_dir: "tmp/blacklight-core-prune-stale-test")
    ) do |solr_wrapper|
      solr_wrapper.with_collection(name: "blacklight-core", dir: Rails.root.join("solr", "conf").to_s) do
        yield RSolr.connect(url: "http://127.0.0.1:8985/solr/blacklight-core")
      end
    end
  end
end
