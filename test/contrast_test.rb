# frozen_string_literal: true

require_relative "test_helper"

# Menjaga kontras warna tetap memenuhi WCAG 2.1 AA.
#
# Token warna dibaca langsung dari assets/css/site.css, jadi test ini ikut
# gagal begitu ada yang mengubah paletnya menjadi terlalu pucat. Nilai ambang
# 4,5 berlaku untuk teks berukuran normal.
class ContrastTest < Minitest::Test
  include TestSupport

  AA_NORMAL = 4.5
  AA_LARGE = 3.0

  def css
    @css ||= File.read(File.join(ROOT, "assets", "css", "site.css"), encoding: "utf-8")
  end

  # Ambil nilai token dari blok :root (tema terang) atau :root[data-theme="dark"].
  def tokens(theme)
    @tokens ||= {}
    @tokens[theme] ||= begin
      block = theme == :dark ? css[/:root\[data-theme="dark"\]\s*\{(.+?)\n\}/m, 1] : css[/^:root \{(.+?)\n\}/m, 1]
      refute_nil block, "blok token #{theme} tidak ditemukan"
      block.scan(/--([\w-]+):\s*(#[0-9a-fA-F]{6})/).to_h
    end
  end

  def channel(value)
    v = value / 255.0
    v <= 0.03928 ? v / 12.92 : (((v + 0.055) / 1.055)**2.4)
  end

  def luminance(hex)
    r, g, b = hex.delete("#").scan(/../).map { |part| channel(part.to_i(16)) }
    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  end

  def contrast(foreground, background)
    a = luminance(foreground)
    b = luminance(background)
    ((([a, b].max) + 0.05) / (([a, b].min) + 0.05)).round(2)
  end

  # Pasangan warna yang benar-benar dipakai di antarmuka.
  PAIRS = [
    ["ink",     "bg",        AA_NORMAL, "teks utama di atas latar halaman"],
    ["ink",     "surface",   AA_NORMAL, "teks utama di atas kartu"],
    ["ink-2",   "surface",   AA_NORMAL, "teks sekunder di atas kartu"],
    ["ink-2",   "surface-2", AA_NORMAL, "angka pada chip dan ringkasan"],
    ["ink-3",   "surface",   AA_NORMAL, "teks tersier di atas kartu"],
    ["ink-3",   "bg",        AA_NORMAL, "teks tersier di atas latar halaman"],
    ["brand",   "surface",   AA_LARGE,  "harga dan aksen di atas kartu"],
    ["ok-ink",  "ok",        AA_NORMAL, "teks lencana Baru"],
    ["warn-ink", "warn",     AA_NORMAL, "teks lencana Stok Terbatas"],
    ["brand-ink", "brand",   AA_NORMAL, "teks tombol utama"]
  ].freeze

  def test_kontras_tema_terang_memenuhi_wcag_aa
    assert_pairs(:light)
  end

  def test_kontras_tema_gelap_memenuhi_wcag_aa
    assert_pairs(:dark)
  end

  def assert_pairs(theme)
    palette = tokens(theme)
    gagal = []

    PAIRS.each do |fg, bg, threshold, label|
      f = palette[fg]
      b = palette[bg]
      next if f.nil? || b.nil?

      value = contrast(f, b)
      gagal << "#{label} (--#{fg} #{f} / --#{bg} #{b}) = #{value}, minimal #{threshold}" if value < threshold
    end

    assert_empty gagal, "kontras #{theme} gagal:\n  " + gagal.join("\n  ")
  end

  # Hijau WhatsApp resmi terlalu terang untuk teks putih, jadi dipakai versi
  # yang sudah digelapkan. Test ini mencegahnya dikembalikan.
  def test_tombol_whatsapp_cukup_kontras
    hex = css[/\.btn--wa \{ --btn-bg: (#[0-9a-fA-F]{6});/, 1]
    refute_nil hex, "warna tombol WhatsApp tidak ditemukan"
    assert_operator contrast("#ffffff", hex), :>=, AA_NORMAL,
                    "tombol WhatsApp #{hex} tidak cukup kontras dengan teks putih"
  end

  def test_tombol_mengambang_memakai_warna_yang_sama
    fab = css[/\.fab \{(.+?)\n\}/m, 1]
    refute_nil fab
    hex = fab[/background:\s*(#[0-9a-fA-F]{6})/, 1]
    assert_operator contrast("#ffffff", hex), :>=, AA_NORMAL,
                    "tombol mengambang #{hex} tidak cukup kontras"
  end

  # Regresi: teks footer sempat memakai opasitas 45 persen dan hanya
  # mencapai 4,48.
  def test_disclaimer_footer_cukup_kontras
    rule = css[/\.disclaimer \{(.+?)\}/m, 1]
    refute_nil rule
    alpha = rule[/rgb\(255 255 255 \/ (\d+)%\)/, 1].to_i
    assert_operator alpha, :>=, 46, "opasitas #{alpha}% terlalu rendah untuk teks di atas footer gelap"
  end
end
