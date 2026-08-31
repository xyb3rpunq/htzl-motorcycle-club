# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/htzl/filters"

# Menjaga agar kelima bahasa tetap sinkron: kunci yang sama, tanpa nilai kosong,
# dan kamus istilah menutupi seluruh data katalog.
class I18nTest < Minitest::Test
  include TestSupport

  BASE = "id"

  def test_semua_berkas_bahasa_ada
    TestSupport::LOCALES.each do |locale|
      path = File.join(ROOT, "_data", "i18n", "#{locale}.yml")

      assert_path_exists path, "berkas bahasa hilang: #{locale}.yml"
    end
  end

  def test_metadata_bahasa_lengkap
    TestSupport::LOCALES.each do |locale|
      dict = i18n(locale)
      %w[locale code html_lang name short flag].each do |key|
        refute_nil dict[key], "#{locale}.yml kehilangan #{key}"
        refute_empty dict[key].to_s, "#{locale}.yml punya #{key} kosong"
      end
      assert_equal locale, dict["locale"]
      assert dict.key?("prefix"), "#{locale}.yml kehilangan prefix"
    end
  end

  def test_kode_bahasa_mengikuti_iso_639_1
    TestSupport::LOCALES.each do |locale|
      assert_match(/\A[a-z]{2}(-[A-Za-z]+)?\z/, i18n(locale)["html_lang"],
                   "html_lang #{locale} bukan kode ISO yang sah")
    end
  end

  def test_awalan_url_unik_dan_bahasa_dasar_di_akar
    prefixes = TestSupport::LOCALES.map { |l| i18n(l)["prefix"] }

    assert_equal prefixes.length, prefixes.uniq.length, "awalan URL tidak boleh kembar"
    assert_equal "", i18n(BASE)["prefix"], "bahasa dasar harus berada di akar situs"
    TestSupport::LOCALES.reject { |l| l == BASE }.each do |locale|
      assert_equal "/#{locale}", i18n(locale)["prefix"]
    end
  end

  def test_struktur_kunci_identik_di_semua_bahasa
    reference = flatten_keys(i18n(BASE)).sort

    TestSupport::LOCALES.reject { |l| l == BASE }.each do |locale|
      current = flatten_keys(i18n(locale)).sort
      missing = reference - current
      extra = current - reference

      assert_empty missing, "#{locale}.yml kehilangan kunci: #{missing.first(8).join(", ")}"
      assert_empty extra, "#{locale}.yml punya kunci berlebih: #{extra.first(8).join(", ")}"
    end
  end

  def test_tidak_ada_nilai_kosong
    TestSupport::LOCALES.each do |locale|
      kosong = flatten_keys(i18n(locale)).select do |path|
        value = path.split(".").reduce(i18n(locale)) do |acc, part|
          if part =~ /\A(.+)\[(\d+)\]\z/
            acc.is_a?(Hash) ? acc[Regexp.last_match(1)][Regexp.last_match(2).to_i] : nil
          else
            acc.is_a?(Hash) ? acc[part] : nil
          end
        end
        value.to_s.strip.empty? && path != "prefix"
      end

      assert_empty kosong, "#{locale}.yml punya nilai kosong: #{kosong.first(5).join(", ")}"
    end
  end

  def test_placeholder_blurb_konsisten
    %w[blurb_bike blurb_generic].each do |key|
      reference = i18n(BASE)["catalog"][key].scan(/%\{(\w+)\}/).flatten.sort
      TestSupport::LOCALES.each do |locale|
        current = i18n(locale)["catalog"][key].scan(/%\{(\w+)\}/).flatten.sort

        assert_equal reference, current, "#{locale}.yml: placeholder #{key} tidak cocok"
      end
    end
  end

  def test_kamus_menutupi_semua_subkategori
    used = catalog.map { |i| i["subcategory"] }.uniq
    covered = terms["subcategory"].keys

    assert_empty used - covered, "subkategori belum ada di kamus: #{(used - covered).join(", ")}"
  end

  def test_kamus_menutupi_semua_nama_spesifikasi
    used = catalog.flat_map { |i| i["specs"].keys }.uniq
    covered = terms["spec_key"].keys

    assert_empty used - covered, "nama spesifikasi belum ada di kamus: #{(used - covered).join(", ")}"
  end

  def test_kamus_menutupi_semua_label_kategori
    used = catalog.map { |i| i["category_label"] }.uniq

    assert_empty used - terms["category"].keys
  end

  def test_setiap_entri_kamus_punya_empat_terjemahan
    target = TestSupport::LOCALES - [BASE]
    terms.each do |kind, entries|
      entries.each do |source, translations|
        assert_equal target.sort, translations.keys.sort,
                     "kamus #{kind}/#{source} tidak lengkap"
        translations.each do |lang, value|
          refute_empty value.to_s.strip, "kamus #{kind}/#{source}/#{lang} kosong"
        end
      end
    end
  end

  def test_rentang_harga_di_terjemahan_cocok_dengan_kode_ruby
    bands = catalog.map { |i| i["price_band"] }.uniq
    TestSupport::LOCALES.each do |locale|
      keys = i18n(locale)["catalog"]["price_bands"].keys

      assert_empty bands - keys, "#{locale}.yml kehilangan label rentang harga: #{(bands - keys).join(", ")}"
    end
  end

  def test_label_lencana_cocok_dengan_data
    badges = catalog.map { |i| i["badge"] }.compact.uniq
    TestSupport::LOCALES.each do |locale|
      keys = i18n(locale)["catalog"]["badges"].keys

      assert_empty badges - keys, "#{locale}.yml kehilangan label lencana: #{(badges - keys).join(", ")}"
    end
  end

  def test_judul_galeri_menutupi_semua_gambar
    slugs = Dir[File.join(ROOT, "assets", "img", "gallery", "*-thumb.webp")]
            .map { |p| File.basename(p, "-thumb.webp") }
    TestSupport::LOCALES.each do |locale|
      captions = i18n(locale)["gallery"]["captions"].keys

      assert_empty slugs - captions, "#{locale}.yml kehilangan judul galeri: #{(slugs - captions).join(", ")}"
    end
  end

  def test_berita_tersedia_dalam_semua_bahasa
    data_file("news.yml").each do |news|
      TestSupport::LOCALES.each do |locale|
        refute_nil news["title"][locale], "berita #{news["image"]} tidak punya judul #{locale}"
        refute_nil news["topic"][locale], "berita #{news["image"]} tidak punya topik #{locale}"
      end
    end
  end

  # --- nilai spesifikasi -------------------------------------------------
  def spec_values
    @spec_values ||= YAML.load_file(File.join(ROOT, "_data", "i18n", "spec_values.yml"))["spec_value"]
  end

  def test_setiap_nilai_spesifikasi_tercakup
    used = catalog.flat_map { |i| i["specs"].values }.uniq
    missing = used.reject { |v| HTZL::Measures.localize(v, "en") || spec_values.key?(v) }

    assert_empty missing, "nilai belum diterjemahkan: #{missing.first(5).join(", ")}"
  end

  def test_kamus_nilai_tidak_memuat_entri_usang
    used = catalog.flat_map { |i| i["specs"].values }.uniq
    extra = spec_values.keys - used

    assert_empty extra, "entri kamus tidak terpakai: #{extra.first(5).join(", ")}"
  end

  def test_setiap_entri_nilai_punya_empat_bahasa
    target = (TestSupport::LOCALES - [BASE]).sort
    spec_values.each do |source, translations|
      assert_equal target, translations.keys.sort, "nilai '#{source}' tidak lengkap"
      translations.each_value { |v| refute_empty v.to_s.strip }
    end
  end

  def test_nilai_yang_ditangani_otomatis_tidak_perlu_masuk_kamus
    redundant = spec_values.keys.select { |v| HTZL::Measures.localize(v, "en") }

    assert_empty redundant,
                 "nilai ini sudah ditangani otomatis, hapus dari kamus: #{redundant.first(5).join(", ")}"
  end

  # --- penulisan tanggal -------------------------------------------------
  def test_setiap_bahasa_punya_dua_belas_nama_bulan
    TestSupport::LOCALES.each do |locale|
      months = i18n(locale).dig("date", "months")

      refute_nil months, "#{locale}.yml tidak punya nama bulan"
      assert_equal 12, months.length, "#{locale}.yml: jumlah bulan salah"
      months.each { |m| refute_empty m.to_s.strip }
    end
  end

  def test_pola_tanggal_memuat_placeholder_yang_dibutuhkan
    TestSupport::LOCALES.each do |locale|
      pattern = i18n(locale).dig("date", "pattern")

      refute_nil pattern, "#{locale}.yml tidak punya pola tanggal"
      ["%{d}", "%{m}", "%{y}"].each do |token|
        assert_includes pattern, token, "#{locale}.yml: pola tanggal kehilangan #{token}"
      end
    end
  end
end
