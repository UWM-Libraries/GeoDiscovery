# frozen_string_literal: true

# Represent a single document returned from Solr
class SolrDocument
  include Blacklight::Solr::Document
  include Geoblacklight::SolrDocument
  include WmsRewriteConcern
  include WmsRewriteConcern

  NON_LATIN_LEADING_TITLE = /\A[^\p{Latin}\p{Nd}]/u

  # self.unique_key = 'id'
  self.unique_key = Settings.FIELDS.UNIQUE_KEY

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  # Show the download button regardless of restriction
  def public?
    true
  end

  def title
    self[Settings.FIELDS.TITLE].to_s
  end

  def transliterated_title
    self[Settings.FIELDS.TITLE_TRANSLITERATED].to_s.presence
  end

  def preferred_index_title
    return title unless non_latin_leading_title?

    transliterated_title || title
  end

  def show_original_title_companion?
    transliterated_title.present? && transliterated_title != title && non_latin_leading_title?
  end

  def non_latin_leading_title?
    title.match?(NON_LATIN_LEADING_TITLE)
  end

end
