# frozen_string_literal: true

return unless defined?(GeoCombine::GeoBlacklightHarvester)

existing_transformer = GeoCombine::GeoBlacklightHarvester.document_transformer

GeoCombine::GeoBlacklightHarvester.document_transformer = lambda do |document|
  document = existing_transformer.call(document) if existing_transformer
  TitleTransliterator.add_to_document(document)
end
