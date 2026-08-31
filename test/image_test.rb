# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/htzl/image_size"

# Gambar adalah bagian terberat dari halaman katalog. Berkas uji ini menjaga
# tiga hal: ukuran yang ditulis ke HTML memang ukuran berkasnya, tiap varian
# srcset benar-benar ada, dan tidak ada berkas yang membengkak diam-diam.
class ImageTest < Minitest::Test
  include TestSupport

  RASTER = "assets/img"
  THUMB_WIDTHS = [384, 640].freeze

  def photos
    @photos ||= Dir.glob(File.join(ROOT, RASTER, "**", "*.webp"))
  end

  def vectors
    @vectors ||= Dir.glob(File.join(ROOT, RASTER, "**", "*.svg"))
  end

  def path_for(web_path)
    File.join(ROOT, web_path.sub(%r{\A/}, ""))
  end

  def test_pembaca_ukuran_mengenali_semua_berkas_gambar
    berkas = photos + vectors

    refute_empty berkas

    gagal = berkas.reject { |path| HTZL::ImageSize.read(path) }

    assert_empty gagal, "tidak terbaca: #{gagal.first(5).join(", ")}"
  end

  def test_pembaca_ukuran_menolak_masukan_yang_bukan_gambar
    assert_nil HTZL::ImageSize.read(File.join(ROOT, "tidak-ada.webp"))
    assert_nil HTZL::ImageSize.read(File.join(ROOT, "Gemfile"))
  end

  def test_pembaca_ukuran_cocok_dengan_atribut_svg
    vectors.each do |path|
      width, height = HTZL::ImageSize.read(path)
      head = File.read(path, 500, encoding: "utf-8")

      assert_equal head[/width="(\d+)"/, 1].to_i, width, path
      assert_equal head[/height="(\d+)"/, 1].to_i, height, path
    end
  end

  # Atribut width dan height mencegah tata letak melompat saat gambar selesai
  # dimuat, tetapi hanya kalau angkanya benar.
  def test_setiap_item_menyimpan_ukuran_gambar_yang_sebenarnya
    catalog.each do |item|
      size = item["image_size"]

      refute_nil size, "#{item["sku"]} tanpa ukuran gambar"
      assert_equal 2, size.size
      assert_equal HTZL::ImageSize.read(path_for(item["image"])), size,
                   "#{item["sku"]}: #{item["image"]}"
    end
  end

  def test_rasio_gambar_seragam_agar_kartu_tidak_bergeser
    rasio = catalog.map { |item| (item["image_size"][0] / item["image_size"][1].to_f).round(2) }.uniq

    assert_equal 1, rasio.size, "rasio bercampur: #{rasio.inspect}"
  end

  def test_setiap_varian_srcset_ada_dan_ukurannya_menaik
    berfoto = catalog.select { |item| item["image_srcset"] }

    refute_empty berfoto

    berfoto.each do |item|
      lebar = item["image_srcset"].map(&:last)

      assert_equal lebar.sort, lebar, "#{item["sku"]}: urutan lebar tidak menaik"
      assert_equal lebar.uniq, lebar, "#{item["sku"]}: lebar ganda"
      assert_equal item["image_size"][0], lebar.last,
                   "#{item["sku"]}: kandidat terbesar bukan berkas penuh"

      item["image_srcset"].each do |web_path, width|
        path = path_for(web_path)

        assert_path_exists path, "#{item["sku"]}: #{web_path} tidak ada"
        assert_equal width, HTZL::ImageSize.read(path)[0], web_path
      end
    end
  end

  def test_varian_kecil_memang_lebih_ringan_dari_berkas_penuh
    catalog.select { |item| item["image_srcset"] && item["image_srcset"].size > 1 }.each do |item|
      ukuran = item["image_srcset"].map { |web_path, _| File.size(path_for(web_path)) }

      assert_equal ukuran.sort, ukuran, "#{item["sku"]}: varian kecil tidak lebih ringan"
    end
  end

  def test_gambar_vektor_tidak_diberi_srcset
    catalog.select { |item| item["image"].end_with?(".svg") }.each do |item|
      assert_nil item["image_srcset"], "#{item["sku"]}: SVG tidak perlu srcset"
    end
  end

  # Berkas penuh dipakai dialog dan layar retina; varian dipakai kartu.
  def test_tidak_ada_berkas_gambar_yang_kelewat_berat
    batas = { full: 200 * 1024, thumb: 60 * 1024 }

    photos.each do |path|
      varian = THUMB_WIDTHS.any? { |w| File.basename(path, ".webp").end_with?("-#{w}") }

      assert_operator File.size(path), :<=, varian ? batas[:thumb] : batas[:full],
                      "#{File.basename(path)} #{File.size(path) / 1024} KB"
    end
  end

  def test_tidak_ada_varian_yatim_tanpa_berkas_penuh
    yatim = photos.select do |path|
      stem = File.basename(path, ".webp")
      width = THUMB_WIDTHS.find { |w| stem.end_with?("-#{w}") }
      width && !File.exist?(path.sub("-#{width}.webp", ".webp"))
    end

    assert_empty(yatim.map { |p| File.basename(p) })
  end
end
