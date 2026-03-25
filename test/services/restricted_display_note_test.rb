# frozen_string_literal: true

require "test_helper"
require "json"
require "tmpdir"

class RestrictedDisplayNoteTest < ActiveSupport::TestCase
  test "adds the restricted warning to restricted documents" do
    document = RestrictedDisplayNote.add_to_document(
      {"dct_accessRights_s" => "Restricted"}
    )

    assert_equal [RestrictedDisplayNote::NOTE], document["gbl_displayNote_sm"]
  end

  test "does not add the restricted warning to public documents" do
    document = RestrictedDisplayNote.add_to_document(
      {"dct_accessRights_s" => "Public"}
    )

    assert_nil document["gbl_displayNote_sm"]
  end

  test "does not duplicate an existing restricted warning" do
    document = RestrictedDisplayNote.add_to_document(
      {
        "dct_accessRights_s" => "Restricted",
        "gbl_displayNote_sm" => [RestrictedDisplayNote::NOTE]
      }
    )

    assert_equal [RestrictedDisplayNote::NOTE], document["gbl_displayNote_sm"]
  end

  test "does not add the restricted warning to restricted edu.uwm records" do
    document = RestrictedDisplayNote.add_to_document(
      {"dct_accessRights_s" => "Restricted"},
      source_path: "/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/edu.uwm/metadata-aardvark/gmgs0c4sj6k_BL_Aardvark.json"
    )

    assert_nil document["gbl_displayNote_sm"]
  end

  test "geo combine harvester docs_to_index adds restricted display note for restricted ogm records" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "edu.stanford.purl", "metadata-aardvark"))
      File.write(
        File.join(dir, "edu.stanford.purl", "metadata-aardvark", "stanford-dp018hs9766.json"),
        JSON.generate(gbl_fixture_document("actual-raster1.json"))
      )

      harvester = GeoCombine::Harvester.new(ogm_path: dir, schema_version: "Aardvark")
      document, = harvester.docs_to_index.first

      assert_includes document["gbl_displayNote_sm"], RestrictedDisplayNote::NOTE
    end
  end

  test "geo combine harvester docs_to_index skips restricted display note for restricted edu.uwm records" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "edu.uwm", "metadata-aardvark"))
      File.write(
        File.join(dir, "edu.uwm", "metadata-aardvark", "gmgs0c4sj6k_BL_Aardvark.json"),
        JSON.generate(gbl_fixture_document("actual-raster1.json"))
      )

      harvester = GeoCombine::Harvester.new(ogm_path: dir, schema_version: "Aardvark")
      document, = harvester.docs_to_index.first

      assert_nil document["gbl_displayNote_sm"]
    end
  end

  private

  def gbl_fixture_document(filename)
    JSON.parse(Rails.root.join("test/fixtures/files/gbl_documents", filename).read)
  end
end
