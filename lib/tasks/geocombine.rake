# frozen_string_literal: true

Rake::Task["geocombine:index"].clear if Rake::Task.task_defined?("geocombine:index")

namespace :geocombine do
  desc "Index all JSON documents except Layers.json with the Rails environment loaded"
  task index: :environment do
    harvester = GeoCombine::Harvester.new
    indexer = GeoCombine::Indexer.new
    indexer.index(harvester.docs_to_index)
  end
end
