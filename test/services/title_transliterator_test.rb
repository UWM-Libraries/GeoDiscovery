# frozen_string_literal: true

require "test_helper"
require "json"

class TitleTransliteratorTest < ActiveSupport::TestCase
  setup do
    TitleTransliterator.reset_cache!
  end

  test "transliterates non latin titles into readable latin text" do
    assert_equal "bei jing shi cheng qu jie dao tu", TitleTransliterator.transliterate("北京市城区街道图")
    assert_equal "Athena", TitleTransliterator.transliterate("Αθήνα")
    assert_equal "Karta", TitleTransliterator.transliterate("Карта")
  end

  test "adds transliterated title field to documents" do
    document = TitleTransliterator.add_to_document({"dct_title_s" => "北京市城区街道图"})

    assert_equal "bei jing shi cheng qu jie dao tu", document["dct_title_transliterated_s"]
  end

  test "adds transliterated title field to uwm fixture documents used for indexing" do
    document = TitleTransliterator.add_to_document(uwm_fixture_document("transliterated_sort_test_BL_Aardvark.json"))

    assert_equal "bei jing shi cheng qu jie dao tu", document["dct_title_transliterated_s"]
  end

  test "does not shell out for latin leading titles" do
    with_capture3_stub(->(*) { flunk("uconv should not be called for latin-leading titles") }) do
      assert_nil TitleTransliterator.transliterate("Alabama county boundaries")
      assert_nil TitleTransliterator.transliterate("  Alabama county boundaries")
      assert_nil TitleTransliterator.transliterate("!Alabama county boundaries")
    end
  end

  test "caches transliteration results by title" do
    calls = 0
    fake_status = Struct.new(:success?).new(true)
    fake_result = ["bei jing shi cheng qu jie dao tu\n", "", fake_status]

    with_capture3_stub(lambda { |*|
      calls += 1
      fake_result
    }) do
      2.times { TitleTransliterator.transliterate("北京市城区街道图") }
    end

    assert_equal 1, calls
  end

  private

  def with_capture3_stub(replacement)
    original = Open3.method(:capture3)
    Open3.singleton_class.send(:define_method, :capture3, replacement)
    yield
  ensure
    Open3.singleton_class.send(:define_method, :capture3, original)
  end

  def uwm_fixture_document(filename)
    JSON.parse(Rails.root.join("test/fixtures/files/uwm_documents", filename).read)
  end
end
