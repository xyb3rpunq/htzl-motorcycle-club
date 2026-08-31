# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require_relative "../lib/htzl/image_size"

# Jalur pertahanan pembaca dimensi gambar.
#
# Semua berkas di repo ini kebetulan WebP lossy yang sehat, sehingga cabang
# untuk berkas rusak, terpotong, atau berformat lain tidak pernah dijalankan
# sekali pun. Justru itu kode yang paling mungkin salah. Di sini headernya
# disusun byte demi byte supaya tiap cabang benar-benar diuji.
class ImageSizeEdgeTest < Minitest::Test
  # 12 byte pertama sama untuk semua WebP: penanda RIFF, ukuran berkas,
  # lalu penanda WEBP.
  def riff(chunk, payload)
    body = chunk + [payload.bytesize].pack("V") + payload
    "RIFF" + [4 + body.bytesize].pack("V") + "WEBP" + body
  end

  def lossy(width, height, sync: [0x9d, 0x01, 0x2a])
    # Byte 12..22 adalah "VP8 ", ukuran chunk, dan tiga byte tag bingkai.
    payload = [0, 0, 0].pack("C3") + sync.pack("C3") +
              [width, height].pack("v2") + ("\0" * 8)
    riff("VP8 ", payload)
  end

  def lossless(width, height, signature: 0x2f)
    bits = (width - 1) | ((height - 1) << 14)
    riff("VP8L", [signature].pack("C") + [bits].pack("V") + ("\0" * 12))
  end

  def extended(width, height)
    canvas = [width - 1, height - 1].flat_map { |v| [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff] }
    riff("VP8X", ("\0" * 4) + canvas.pack("C6") + ("\0" * 8))
  end

  def with_file(bytes, ext: ".webp")
    Dir.mktmpdir do |dir|
      path = File.join(dir, "uji#{ext}")
      File.binwrite(path, bytes)
      yield path
    end
  end

  def test_membaca_webp_lossless
    with_file(lossless(1234, 567)) do |path|
      assert_equal [1234, 567], HTZL::ImageSize.read(path)
    end
  end

  def test_membaca_webp_extended
    with_file(extended(4096, 2160)) do |path|
      assert_equal [4096, 2160], HTZL::ImageSize.read(path)
    end
  end

  def test_lebar_lossy_dibatasi_empat_belas_bit
    # Dua bit teratas pada WebP lossy adalah penanda skala, bukan bagian ukuran.
    with_file(lossy(0xC000 | 640, 0x8000 | 480)) do |path|
      assert_equal [640, 480], HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_penanda_bingkai_lossy_yang_rusak
    with_file(lossy(640, 480, sync: [0x00, 0x01, 0x02])) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_tanda_lossless_yang_rusak
    with_file(lossless(640, 480, signature: 0x00)) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_jenis_chunk_yang_tidak_dikenal
    with_file(riff("XXXX", "\0" * 20)) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_berkas_yang_terpotong
    with_file(lossy(640, 480)[0, 20]) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_berkas_yang_bukan_riff
    with_file("BUKANWEBP" + ("\0" * 40)) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_menolak_berkas_riff_yang_bukan_webp
    with_file("RIFF" + [40].pack("V") + "AVI " + ("\0" * 32)) do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_svg_tanpa_atribut_ukuran_dianggap_tidak_terbaca
    with_file('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"></svg>', ext: ".svg") do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end

  def test_svg_dengan_atribut_ukuran_terbaca
    with_file('<svg xmlns="http://www.w3.org/2000/svg" width="96" height="72"></svg>', ext: ".svg") do |path|
      assert_equal [96, 72], HTZL::ImageSize.read(path)
    end
  end

  def test_ekstensi_di_luar_webp_dan_svg_diabaikan
    with_file(lossy(640, 480), ext: ".png") do |path|
      assert_nil HTZL::ImageSize.read(path)
    end
  end
end
