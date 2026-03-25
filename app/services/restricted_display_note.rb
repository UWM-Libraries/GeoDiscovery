# frozen_string_literal: true

class RestrictedDisplayNote
  FIELD = "gbl_displayNote_sm"
  NOTE = "Warning: This dataset is restricted and you may not be able to access the resource. Contact the dataset provider or the AGSL for assistance."
  UWM_REPOSITORY_PATH_FRAGMENT = "/edu.uwm/"

  class << self
    def add_to_document(document, source_path: nil)
      return document unless document["dct_accessRights_s"] == "Restricted"
      return document if source_path.to_s.include?(UWM_REPOSITORY_PATH_FRAGMENT)

      existing_notes = Array(document[FIELD]).flatten.compact_blank
      return document if existing_notes.include?(NOTE)

      document.merge(FIELD => existing_notes + [NOTE])
    end
  end
end
