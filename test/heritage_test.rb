# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/htzl/heritage"

# Koleksi Harley-Davidson dan foto berlisensi bebas yang menyertainya.
class HeritageTest < Minitest::Test
  include TestSupport

  FREE_LICENSE = /\A(public domain|cc0|cc by)/i

  def units
    @units ||= catalog.select { |i| i["category"] == "heritage" }
  end

  def credits
    @credits ||= begin
      path = File.join(ROOT, "_data", "photo_credits.yml")
      File.exist?(path) ? (YAML.load_file(path) || []) : []
    end
  end

  # --- kelengkapan koleksi ----------------------------------------------
  def test_koleksi_berisi_tepat_seratus_unit
    assert_equal 100, HTZL::Heritage::UNITS.length
    assert_equal 100, units.length
  end

  def test_unit_diurutkan_dari_yang_tertua
    years = HTZL::Heritage::UNITS.map(&:first)
    assert_equal years.sort, years, "unit harus urut dari tahun tertua"
    assert_equal 1903, years.first
  end

  def test_nama_unit_unik
    names = HTZL::Heritage::UNITS.map { |u| u[1] }
    duplikat = names.tally.select { |_, v| v > 1 }.keys
    assert_empty duplikat, "nama kembar: #{duplikat.join(', ')}"
  end

  def test_setiap_unit_memakai_merek_harley_davidson
    units.each { |u| assert_equal "Harley-Davidson", u["brand"] }
  end

  def test_nama_unit_memuat_tahunnya
    units.each do |unit|
      assert_includes unit["name"], unit["year"].to_s,
                      "#{unit['name']} tidak memuat tahun produksinya"
    end
  end

  def test_spesifikasi_unit_lengkap
    wajib = %w[Tahun Mesin Tenaga Tipe Rangka Kelangkaan]
    units.each do |unit|
      assert_equal wajib.sort, unit["specs"].keys.sort, "#{unit['name']}: spesifikasi tidak lengkap"
    end
  end

  def test_subkategori_mengikuti_generasi_mesin
    HTZL::Heritage::UNITS.each do |_, name, era, *|
      sub = HTZL::Heritage.subcategory(era)
      refute_equal "Era Lainnya", sub, "#{name} (#{era}) belum dipetakan ke generasi mesin"
    end
  end

  def test_harga_koleksi_masuk_akal
    units.each do |unit|
      assert_operator unit["price"], :>=, 100_000_000, "#{unit['name']}: harga terlalu rendah untuk koleksi"
      assert_operator unit["price"], :<=, 10_000_000_000, "#{unit['name']}: harga di luar nalar"
    end
  end

  # --- foto dan lisensi --------------------------------------------------
  def test_setiap_unit_punya_gambar
    units.each { |u| refute_nil u["image"], "#{u['name']} tidak punya gambar" }
  end

  def test_semua_foto_memakai_lisensi_bebas
    credits.each do |credit|
      assert_match FREE_LICENSE, credit["license"],
                   "#{credit['slug']}: lisensi '#{credit['license']}' bukan lisensi bebas"
    end
  end

  def test_setiap_foto_mencantumkan_atribusi_lengkap
    credits.each do |credit|
      %w[title author license source].each do |field|
        refute_empty credit[field].to_s.strip, "#{credit['slug']}: kolom #{field} kosong"
      end
      assert_match %r{\Ahttps://commons\.wikimedia\.org/}, credit["source"],
                   "#{credit['slug']}: sumber harus menunjuk Wikimedia Commons"
    end
  end

  def test_berkas_foto_benar_benar_ada
    credits.each do |credit|
      path = File.join(ROOT, credit["file"].sub(%r{\A/}, ""))
      assert File.exist?(path), "berkas foto hilang: #{credit['file']}"
      assert_operator File.size(path), :<, 200 * 1024, "#{credit['slug']}: foto terlalu besar"
    end
  end

  def test_unit_berfoto_membawa_kredit_ke_katalog
    berfoto = units.select { |u| u["image"].to_s.include?("/heritage/") }
    assert_equal credits.length, berfoto.length
    berfoto.each do |unit|
      refute_nil unit["credit"], "#{unit['name']}: foto tanpa data atribusi"
      assert_equal %w[author license license_url source title].sort,
                   unit["credit"].keys.sort
    end
  end

  def test_unit_tanpa_foto_memakai_artwork_yang_dibuat_sendiri
    tanpa_foto = units.reject { |u| u["credit"] }
    tanpa_foto.each do |unit|
      assert_includes unit["image"], "/assets/img/products/",
                      "#{unit['name']}: seharusnya memakai artwork"
    end
  end

  # --- artwork untuk item non-motor --------------------------------------
  def test_semua_item_punya_gambar
    tanpa = catalog.reject { |i| i["image"] }.map { |i| i["name"] }
    assert_empty tanpa, "item tanpa gambar: #{tanpa.first(5).join(', ')}"
  end

  def test_artwork_berupa_svg_yang_ringan
    Dir[File.join(ROOT, "assets", "img", "products", "*.svg")].each do |path|
      assert_operator File.size(path), :<, 8 * 1024, "#{File.basename(path)}: artwork terlalu besar"
      svg = File.read(path, encoding: "utf-8")
      assert_match(/\A<svg /, svg)
      assert_includes svg, 'role="img"'
      assert_includes svg, "aria-label="
      refute_match %r{https?://(?!www\.w3\.org)}, svg, "artwork tidak boleh menarik aset eksternal"
    end
  end
end
