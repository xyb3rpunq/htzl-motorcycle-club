# frozen_string_literal: true

require_relative "test_helper"
require "digest"
require "base64"
require_relative "../lib/htzl/filters"

# Content-Security-Policy dinyatakan lewat meta karena GitHub Pages tidak bisa
# mengirim header HTTP sendiri. Kebijakan yang salah tulis diabaikan peramban
# tanpa suara, jadi isinya diperiksa di sini dan penegakannya diuji di
# test/e2e/security.e2e.mjs.
class CspTest < Minitest::Test
  include TestSupport

  def setup
    skip "jalankan `rake build` lebih dulu" unless site_built?
  end

  def pages
    @pages ||= Dir[File.join(ROOT, "_site", "**", "*.html")]
  end

  def policy(html)
    html[/<meta http-equiv="Content-Security-Policy" content="([^"]*)"/, 1]
  end

  def directives(html)
    policy(html).to_s.split(";").to_h do |bagian|
      nama, *nilai = bagian.strip.split(/\s+/)
      [nama, nilai]
    end
  end

  def inline_scripts(html)
    html.scan(%r{<script>(.*?)</script>}m).flatten
  end

  def sha(script)
    "sha256-#{Base64.strict_encode64(Digest::SHA256.digest(script))}"
  end

  def test_filter_menghasilkan_sidik_jari_yang_benar
    subject = Object.new.extend(HTZL::Filters)

    assert_equal "sha256-bhHHL3z2vDgxUt0W3dWQOrprscmda2Y5pLsLg4GF+pI=", subject.csp_hash("alert(1)")
    assert_equal "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=", subject.csp_hash("")
    assert_equal subject.csp_hash("a"), subject.csp_hash("a")
    refute_equal subject.csp_hash("a"), subject.csp_hash("b")
  end

  def test_setiap_halaman_menyatakan_kebijakan
    pages.each do |path|
      html = File.read(path, encoding: "utf-8")

      refute_nil policy(html), "#{path.sub("#{ROOT}/_site/", "")} tanpa CSP"
    end
  end

  # Inilah bagian yang paling mudah salah: satu spasi berubah di skrip inline
  # dan sidik jarinya tidak lagi cocok, sehingga skripnya diblokir diam-diam.
  def test_sidik_jari_setiap_skrip_inline_ada_di_kebijakannya
    tidak_cocok = []
    pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      izin = directives(html)["script-src"].to_s
      inline_scripts(html).each do |script|
        tidak_cocok << path.sub("#{ROOT}/_site/", "") unless izin.include?(sha(script))
      end
    end

    assert_empty tidak_cocok.uniq
  end

  def test_skrip_tidak_diizinkan_secara_sembarangan
    pages.each do |path|
      script_src = directives(File.read(path, encoding: "utf-8"))["script-src"]

      refute_includes script_src, "'unsafe-inline'", path
      refute_includes script_src, "'unsafe-eval'", path
      refute_includes script_src, "*", path
    end
  end

  def test_arahan_penting_ada_dan_terkunci
    arahan = directives(File.read(File.join(ROOT, "_site", "catalog", "index.html"), encoding: "utf-8"))

    assert_equal ["'self'"], arahan["default-src"]
    assert_equal ["'none'"], arahan["object-src"]
    assert_equal ["'none'"], arahan["frame-src"]
    assert_equal ["'self'"], arahan["base-uri"]
    assert_equal ["'self'"], arahan["form-action"]
    assert_equal ["'self'"], arahan["img-src"]
    assert_equal ["'self'"], arahan["connect-src"]
  end

  # frame-ancestors hanya berlaku sebagai header dan diabaikan di meta.
  # Menuliskannya di sini justru memberi rasa aman yang keliru.
  def test_tidak_menuliskan_arahan_yang_diabaikan_di_meta
    kebijakan = policy(File.read(File.join(ROOT, "_site", "index.html"), encoding: "utf-8"))

    refute_includes kebijakan, "frame-ancestors"
    refute_includes kebijakan, "report-uri"
  end

  def test_kebijakan_referrer_dinyatakan
    pages.each do |path|
      html = File.read(path, encoding: "utf-8")

      assert_includes html, '<meta name="referrer" content="strict-origin-when-cross-origin">',
                      path.sub("#{ROOT}/_site/", "")
    end
  end

  # Kebijakan harus berada sebelum skrip yang diizinkannya; meta yang datang
  # setelah skrip tidak berlaku untuk skrip itu.
  def test_kebijakan_dinyatakan_sebelum_skrip_pertama
    pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      posisi_csp = html.index("Content-Security-Policy")
      posisi_skrip = html.index("<script")

      assert_operator posisi_csp, :<, posisi_skrip, path.sub("#{ROOT}/_site/", "")
    end
  end
end
