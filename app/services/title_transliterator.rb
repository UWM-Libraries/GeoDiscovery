# frozen_string_literal: true

require "open3"

class TitleTransliterator
  FIELD = "agsl_title_transliterated_s"
  SORT_SOURCE_FIELD = "agsl_title_sort_source_s"
  ICU_TRANSFORM = "Any-Latin; Latin-ASCII"
  MISSING_DEPENDENCY_MESSAGE = "Title transliteration requires the ICU 'uconv' binary to be installed and on PATH."
  TOO_MANY_FILES_MESSAGE = "Title transliteration disabled for this process after hitting the open file limit while running 'uconv'."
  LEADING_NON_ALNUM = /\A[^\p{L}\p{Nd}]+/u
  LATIN_LEADING = /\A[\p{Latin}\p{Nd}]/u
  TITLE_OVERRIDES = {
    "princeton-dcdb78tr193" => "Tibet and adjacent areas under Chinese rule"
  }.freeze

  @cache = {}
  @disabled = false

  class << self
    def add_to_document(document)
      title = document["dct_title_s"].to_s
      override = TITLE_OVERRIDES[document["id"].to_s]
      transliterated = override || transliterate(title)
      sort_source = override || title

      document = document.merge(SORT_SOURCE_FIELD => sort_source)
      return document if transliterated.blank?

      document.merge(FIELD => transliterated)
    end

    def transliterate(title)
      return if title.blank?
      return unless needs_transliteration?(title)
      return if @disabled
      return @cache[title] if @cache.key?(title)

      stdout, stderr, status = Open3.capture3("uconv", "-x", ICU_TRANSFORM, stdin_data: title)
      return @cache[title] = nil if !status.success? || stderr.present?

      transliterated = stdout.strip.gsub(/\s+/, " ")
      return @cache[title] = nil if transliterated.blank? || transliterated == title

      @cache[title] = transliterated
    rescue Errno::ENOENT
      Rails.logger.warn(MISSING_DEPENDENCY_MESSAGE) if defined?(Rails)
      nil
    rescue Errno::EMFILE
      disable_transliteration!(TOO_MANY_FILES_MESSAGE)
      nil
    end

    def reset_cache!
      @cache = {}
      @disabled = false
    end

    private

    def disable_transliteration!(message)
      @disabled = true
      Rails.logger.warn(message) if defined?(Rails)
    end

    def needs_transliteration?(title)
      normalized = title.sub(LEADING_NON_ALNUM, "")
      return false if normalized.blank?

      !normalized.match?(LATIN_LEADING)
    end
  end
end
