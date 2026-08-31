# frozen_string_literal: true

require_relative "test_helper"

# Penjaga regresi untuk aturan CSS yang pernah menimbulkan bug nyata.
# Bug ini ditemukan saat pengujian di lebar layar 375 px dan 1366 px.
class CssTest < Minitest::Test
  include TestSupport

  def css
    @css ||= File.read(File.join(ROOT, "assets", "css", "site.css"), encoding: "utf-8")
  end

  def block(selector)
    css[/#{Regexp.escape(selector)}\s*\{([^}]*)\}/m, 1]
  end

  # Regresi: backdrop-filter pada .site-header membuat containing block baru
  # untuk keturunan position:fixed, sehingga drawer mobile di dalam header
  # ikut terpotong setinggi header (60 px) dan menunya tidak terlihat.
  def test_site_header_tidak_memakai_backdrop_filter_langsung
    header = block(".site-header")
    refute_nil header, "blok .site-header tidak ditemukan"
    refute_match(/backdrop-filter/, header,
                 "backdrop-filter harus dipindah ke pseudo-element, bukan di .site-header")
    refute_match(/\btransform\s*:/, header,
                 "transform pada .site-header juga akan memotong drawer position:fixed")
    refute_match(/\bfilter\s*:/, header,
                 "filter pada .site-header juga akan memotong drawer position:fixed")
  end

  def test_blur_header_tetap_ada_lewat_pseudo_element
    pseudo = block(".site-header::before")
    refute_nil pseudo, "pseudo-element latar header hilang"
    assert_match(/backdrop-filter/, pseudo, "efek blur header hilang")
    assert_match(/z-index:\s*-1/, pseudo, "lapisan blur harus berada di belakang isi header")
  end

  # Regresi: drawer menunggu di luar layar kanan dan membuat halaman bisa
  # digeser mendatar di ponsel.
  def test_body_mencegah_gulir_horizontal
    body = block("body")
    assert_match(/overflow-x:\s*clip/, body,
                 "body butuh overflow-x: clip agar drawer tidak membuat gulir mendatar")
    refute_match(/overflow-x:\s*hidden/, body,
                 "overflow-x: hidden akan mematikan position:sticky pada header")
  end

  # Regresi: panel dropdown bahasa berada dekat tepi kanan dan meluber keluar
  # viewport di layar 1366 px.
  def test_dropdown_tepi_kanan_dibuka_ke_dalam
    rule = block('.dropdown[data-align="end"] .dropdown__panel')
    refute_nil rule, "aturan perataan dropdown tepi kanan hilang"
    assert_match(/inset-inline-end:\s*0/, rule)
    assert_match(/inset-inline-start:\s*auto/, rule)
  end

  def test_dropdown_bahasa_memakai_perataan_tepi
    header = File.read(File.join(ROOT, "_includes", "header.html"), encoding: "utf-8")
    lang_block = header[/<div class="dropdown"[^>]*>\s*<button[^>]*aria-controls="menu-lang"/m]
    refute_nil lang_block, "dropdown bahasa tidak ditemukan di header"
    assert_match(/data-align="end"/, lang_block,
                 "dropdown bahasa harus memakai data-align=\"end\"")
  end

  # Aksesibilitas dan kenyamanan dasar yang mudah hilang saat menata ulang CSS.
  def test_menghormati_preferensi_gerak_minimal
    assert_match(/@media \(prefers-reduced-motion: reduce\)/, css,
                 "situs harus menghormati preferensi gerak minimal")
  end

  def test_target_sentuh_minimal_44_piksel
    assert_match(/min-height:\s*44px/, block(".btn"),
                 "tombol harus setinggi minimal 44 px agar nyaman disentuh")
  end

  def test_tema_gelap_terdefinisi
    assert_match(/:root\[data-theme="dark"\]/, css, "token tema gelap hilang")
  end

  def test_fokus_keyboard_terlihat
    assert_match(/:focus-visible\s*\{[^}]*outline:/m, css,
                 "indikator fokus keyboard wajib ada")
  end

  # Font di-host sendiri: tidak boleh ada permintaan ke server pihak ketiga.
  def test_tidak_ada_aset_dari_pihak_ketiga
    refute_match(%r{@import\s+url\(https?://}, css)
    refute_match(%r{src:\s*url\(["']?https?://}, css, "font harus di-host sendiri")
  end

  def test_halaman_hasil_build_tidak_memuat_aset_eksternal
    skip "jalankan `rake build` lebih dulu" unless site_built?

    izin = %r{https?://(
      wa\.me | www\.instagram\.com | x\.com | www\.linkedin\.com |
      maps\.google\.com | github\.com | www\.ducati\.com | schema\.org |
      commons\.wikimedia\.org | creativecommons\.org | xyb3rpunq\.github\.io
    )}x
    Dir[File.join(ROOT, "_site", "**", "*.html")].each do |path|
      html = File.read(path, encoding: "utf-8")
      html.scan(/(?:src|href)="(https?:\/\/[^"]+)"/).flatten.uniq.each do |url|
        assert_match izin, url, "#{File.basename(File.dirname(path))} memuat aset eksternal: #{url}"
      end
    end
  end

  # Regresi: reset global `* { margin: 0 }` menimpa `margin: auto` bawaan
  # browser untuk <dialog>, sehingga dialog detail produk menempel ke tepi
  # kiri layar alih-alih berada di tengah.
  def test_dialog_dinyatakan_rata_tengah
    rule = block("dialog")
    refute_nil rule, "blok dialog tidak ditemukan"
    assert_match(/margin:\s*auto/, rule,
                 "dialog wajib menyatakan margin: auto karena reset global menimpanya")
  end

  def test_reset_global_memang_menghapus_margin
    assert_match(/\*\s*\{\s*margin:\s*0;\s*\}/, css,
                 "reset global berubah; periksa ulang apakah dialog masih perlu margin: auto")
  end
end
