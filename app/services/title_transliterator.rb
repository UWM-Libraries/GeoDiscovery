# frozen_string_literal: true

require "open3"

class TitleTransliterator
  FIELD = "dct_title_transliterated_s"
  ICU_TRANSFORM = "Any-Latin; Latin-ASCII"
  MISSING_DEPENDENCY_MESSAGE = "Title transliteration requires the ICU 'uconv' binary to be installed and on PATH."
  LEADING_NON_ALNUM = /\A[^\p{L}\p{Nd}]+/u
  LATIN_LEADING = /\A[\p{Latin}\p{Nd}]/u

  @cache = {}

  class << self
    def add_to_document(document)
      title = document["dct_title_s"].to_s
      transliterated = transliterate(title)
      return document if transliterated.blank?

      document.merge(FIELD => transliterated)
    end

    def transliterate(title)
      return if title.blank?
      return unless needs_transliteration?(title)
      return @cache[title] if @cache.key?(title)

      stdout, stderr, status = Open3.capture3("uconv", "-x", ICU_TRANSFORM, stdin_data: title)
      return @cache[title] = nil if !status.success? || stderr.present?

      transliterated = stdout.strip.gsub(/\s+/, " ")
      return @cache[title] = nil if transliterated.blank? || transliterated == title

      @cache[title] = transliterated
    rescue Errno::ENOENT
      Rails.logger.warn(MISSING_DEPENDENCY_MESSAGE) if defined?(Rails)
      nil
    end

    def reset_cache!
      @cache = {}
    end

    private

    def needs_transliteration?(title)
      normalized = title.sub(LEADING_NON_ALNUM, "")
      return false if normalized.blank?

      !normalized.match?(LATIN_LEADING)
    end
  end
end
