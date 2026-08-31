# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/htzl/image_sources"
require_relative "../lib/htzl/filters"

# HTZL::ImageSources memberi tahu ukuran apa saja yang tersedia untuk sebuah
# gambar. Ia tidak boleh pernah menebak: srcset yang menunjuk berkas hilang
# berarti gambar rusak di halaman.
class ImageSourcesTest < Minitest::Test
  include TestSupport

  HERO = "/assets/img/hero/promo.webp"
  CARD = "/assets/img/bikes/kawasaki-x56.webp"

  def test_ukuran_dibaca_dari_berkas
    assert_equal [1400, 788], HTZL::ImageSources.dimensions(HERO)
    assert_equal [630, 390], HTZL::ImageSources.dimensions(CARD)
  end

  def test_ukuran_mengembalikan_salinan_bukan_objek_yang_sama
    first = HTZL::ImageSources.dimensions(HERO)
    first << 999

    assert_equal [1400, 788], HTZL::ImageSources.dimensions(HERO)
  end

  def test_varian_menaik_dan_diakhiri_berkas_penuh
    variants = HTZL::ImageSources.variants(HERO)
    widths = variants.map(&:last)

    assert_equal widths.sort, widths
    assert_equal [HERO, 1400], variants.last
    assert_operator variants.size, :>, 1
  end

  def test_varian_hanya_melaporkan_berkas_yang_ada
    HTZL::ImageSources.variants(HERO).map(&:first).each do |path|
      assert_path_exists HTZL::ImageSources.disk_path(path)
    end
  end

  def test_varian_tidak_pernah_melebihi_lebar_sumber
    HTZL::ImageSources.variants(HERO).map(&:last).each do |width|
      assert_operator width, :<=, 1400
    end
  end

  def test_bukan_webp_dan_masukan_kosong_ditolak
    assert_nil HTZL::ImageSources.variants(nil)
    assert_nil HTZL::ImageSources.variants("/assets/img/art/oli-htzl-4t.svg")
    assert_nil HTZL::ImageSources.dimensions(nil)
  end

  # Setiap varian harus benar-benar lebih ringan dari sumbernya. Kalau tidak,
  # ia hanya menambah berkas tanpa memberi keuntungan apa pun.
  def test_semua_varian_lebih_ringan_dari_sumbernya
    berat = []
    Dir.glob(File.join(ROOT, "assets/img/**/*.webp")).each do |path|
      stem = File.basename(path, ".webp")
      width = HTZL::ImageSources::WIDTHS.find { |w| stem.end_with?("-#{w}") }
      next unless width

      source = path.sub("-#{width}.webp", ".webp")
      next unless File.exist?(source)

      berat << File.basename(path) if File.size(path) >= File.size(source)
    end

    assert_empty berat
  end
end

# Filter Liquid yang memakai daftar ukuran di atas. Template hero dan banner
# bergantung penuh padanya, termasuk untuk baseurl GitHub Pages.
class ImageFiltersTest < Minitest::Test
  include TestSupport

  FakeSite = Struct.new(:data, :config)

  class FakeContext
    attr_reader :registers

    def initialize(site)
      @registers = { site: site }
    end
  end

  def setup
    site = FakeSite.new({}, { "baseurl" => "/htzl-motorcycle-club" })
    @subject = Object.new
    @subject.extend(HTZL::ImageFilters)
    @subject.instance_variable_set(:@context, FakeContext.new(site))
  end

  def test_srcset_memuat_baseurl_dan_satuan_lebar
    hasil = @subject.srcset(ImageSourcesTest::HERO)

    assert_match %r{\A/htzl-motorcycle-club/assets/img/hero/promo-\d+\.webp \d+w}, hasil
    assert_includes hasil, "/htzl-motorcycle-club/assets/img/hero/promo.webp 1400w"
  end

  def test_srcset_kosong_bila_hanya_ada_satu_ukuran
    assert_equal "", @subject.srcset("/assets/img/art/oli-htzl-4t.svg")
  end

  def test_lebar_dan_tinggi_ikut_berkasnya
    assert_equal 1400, @subject.image_width(ImageSourcesTest::HERO)
    assert_equal 788, @subject.image_height(ImageSourcesTest::HERO)
  end

  def test_kandidat_terbesar_selalu_berkas_penuh
    assert_equal "/htzl-motorcycle-club/assets/img/hero/promo.webp",
                 @subject.largest_variant(ImageSourcesTest::HERO)
  end

  def test_kandidat_terbesar_untuk_gambar_tanpa_varian
    # SVG tidak punya varian ukuran; filter harus mengembalikan berkasnya
    # sendiri, bukan meledak.
    assert_equal "/htzl-motorcycle-club/assets/img/art/oli-htzl-4t.svg",
                 @subject.largest_variant("/assets/img/art/oli-htzl-4t.svg")
  end

  def test_lebar_dan_tinggi_untuk_masukan_kosong
    assert_nil @subject.image_width(nil)
    assert_nil @subject.image_height(nil)
  end
end
