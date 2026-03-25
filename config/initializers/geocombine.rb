# frozen_string_literal: true

begin
  require "geo_combine/harvester"
  require "geo_combine/geo_blacklight_harvester"
rescue LoadError
  nil
end

if defined?(GeoCombine::GeoBlacklightHarvester)
  existing_transformer = GeoCombine::GeoBlacklightHarvester.document_transformer

  GeoCombine::GeoBlacklightHarvester.document_transformer = lambda do |document|
    document = existing_transformer.call(document) if existing_transformer
    TitleTransliterator.add_to_document(document)
  end
end

if defined?(GeoCombine::Harvester)
  module GeoCombineHarvesterTransliteration
    def docs_to_index
      return to_enum(:docs_to_index) unless block_given?

      super do |record, path|
        yield TitleTransliterator.add_to_document(record), path
      end
    end
  end

  GeoCombine::Harvester.prepend(GeoCombineHarvesterTransliteration)
end
