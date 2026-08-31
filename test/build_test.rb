# frozen_string_literal: true

require_relative "test_helper"

# Memeriksa hasil build di _site: tautan aset tidak putus, metadata bahasa benar,
# dan tidak ada sisa sintaks Liquid yang gagal dirender.
class BuildTest < Minitest::Test
  include TestSupport

  BASEURL = "/htzl-motorcycle-club"
  PAGES = %w[home catalog kawasaki vixian heritage gallery reserve].freeze

  def setup
    skip "jalankan `rake build` lebih dulu" unless site_built?
  end

  def all_pages
    @all_pages ||= Dir[File.join(ROOT, "_site", "**", "*.html")].sort
  end

  def read_page(*parts)
    File.read(site_path(*parts), encoding: "utf-8")
  end

  def page_path_for(locale, id)
    prefix = locale == "id" ? [] : [locale]
    id == "home" ? site_path(*prefix, "index.html") : site_path(*prefix, id, "index.html")
  end

  # --- kelengkapan halaman ----------------------------------------------
  def test_semua_halaman_terbentuk_untuk_setiap_bahasa
    TestSupport::LOCALES.each do |locale|
      PAGES.each do |id|
        path = page_path_for(locale, id)
        assert File.exist?(path), "halaman hilang: #{locale}/#{id}"
      end
    end
  end

  def test_jumlah_halaman_sesuai_perkiraan
    expected = TestSupport::LOCALES.length * PAGES.length + 1 # +1 untuk 404
    assert_equal expected, all_pages.length,
                 "jumlah halaman tidak sesuai: #{all_pages.length} bukan #{expected}"
  end

  def test_halaman_pendukung_terbentuk
    %w[404.html robots.txt sitemap.xml site.webmanifest .nojekyll assets/catalog.json].each do |file|
      assert File.exist?(site_path(file)), "berkas hilang: #{file}"
    end
  end

  # --- metadata bahasa ---------------------------------------------------
  def test_atribut_lang_sesuai_bahasa_halaman
    TestSupport::LOCALES.each do |locale|
      html = File.read(page_path_for(locale, "home"), encoding: "utf-8")
      expected = i18n(locale)["html_lang"]
      assert_includes html, %(<html lang="#{expected}"), "atribut lang salah di #{locale}"
    end
  end

  def test_setiap_halaman_punya_lima_hreflang_dan_x_default
    TestSupport::LOCALES.each do |locale|
      PAGES.each do |id|
        html = File.read(page_path_for(locale, id), encoding: "utf-8")
        alternates = html.scan(/<link rel="alternate" hreflang="([^"]+)"/).flatten
        assert_equal 6, alternates.length, "#{locale}/#{id}: jumlah hreflang salah"
        assert_includes alternates, "x-default"
      end
    end
  end

  def test_setiap_halaman_punya_canonical_unik
    canonicals = all_pages.map do |path|
      File.read(path, encoding: "utf-8")[/<link rel="canonical" href="([^"]+)"/, 1]
    end.compact
    assert_equal all_pages.length, canonicals.length, "ada halaman tanpa canonical"
    assert_equal canonicals.length, canonicals.uniq.length, "canonical tidak boleh kembar"
  end

  def test_setiap_halaman_punya_judul_dan_deskripsi
    all_pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      title = html[%r{<title>(.*?)</title>}m, 1]
      desc = html[/<meta name="description" content="([^"]*)"/, 1]
      refute_nil title, "#{path} tanpa <title>"
      refute_empty title.to_s.strip, "#{path} punya <title> kosong"
      refute_empty desc.to_s.strip, "#{path} punya deskripsi kosong"
    end
  end

  # --- integritas render -------------------------------------------------
  def test_tidak_ada_sisa_sintaks_liquid
    all_pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      refute_match(/\{\{|\{%/, html, "#{File.basename(File.dirname(path))} masih memuat sintaks Liquid")
    end
  end

  def test_tidak_ada_teks_nil_atau_hash_bocor_ke_html
    all_pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      refute_match(/>\s*\{"[a-z_]+"=>/, html, "#{path} membocorkan struktur Hash Ruby")
    end
  end

  # --- aset --------------------------------------------------------------
  def test_semua_tautan_aset_lokal_mengarah_ke_berkas_yang_ada
    missing = []
    all_pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      html.scan(/(?:src|href)="(#{Regexp.escape(BASEURL)}\/[^"#?]+)"/).flatten.uniq.each do |url|
        target = site_path(url.sub(BASEURL, "").sub(%r{\A/}, ""))
        missing << "#{File.basename(path)} -> #{url}" unless File.exist?(target) || File.directory?(target)
      end
    end
    assert_empty missing.uniq.first(10), "aset tidak ditemukan: #{missing.uniq.first(10).join(', ')}"
  end

  def test_setiap_gambar_punya_alt_lebar_dan_tinggi
    tanpa_alt = []
    tanpa_dimensi = []
    all_pages.each do |path|
      File.read(path, encoding: "utf-8").scan(/<img\b[^>]*>/).each do |tag|
        tanpa_alt << File.basename(path) unless tag.include?("alt=")
        # Gambar lightbox diisi JavaScript sehingga dimensinya diatur CSS.
        next if tag.include?("data-lightbox-img")

        tanpa_dimensi << File.basename(path) unless tag.include?("width=") && tag.include?("height=")
      end
    end
    assert_empty tanpa_alt.uniq, "gambar tanpa atribut alt di: #{tanpa_alt.uniq.join(', ')}"
    assert_empty tanpa_dimensi.uniq, "gambar tanpa width/height di: #{tanpa_dimensi.uniq.join(', ')}"
  end

  def test_semua_ikon_yang_dipakai_terdefinisi_di_sprite
    html = read_page("catalog", "index.html")
    defined_ids = html.scan(/<symbol id="(i-[a-z0-9-]+)"/).flatten.uniq
    refute_empty defined_ids, "sprite ikon tidak ditemukan"

    all_pages.each do |path|
      used = File.read(path, encoding: "utf-8").scan(/<use href="#(i-[a-z0-9-]+)"/).flatten.uniq
      missing = used - defined_ids
      assert_empty missing, "#{File.basename(File.dirname(path))} memakai ikon tak terdefinisi: #{missing.join(', ')}"
    end
  end

  # --- katalog -----------------------------------------------------------
  def test_halaman_katalog_merender_seluruh_item
    TestSupport::LOCALES.each do |locale|
      html = File.read(page_path_for(locale, "catalog"), encoding: "utf-8")
      assert_equal catalog.length, html.scan(/data-item\b/).length,
                   "katalog #{locale} tidak merender semua item"
    end
  end

  def test_kartu_katalog_membawa_atribut_penyaring
    html = read_page("catalog", "index.html")
    card = html[/<article class="card" data-item.*?<\/article>/m]
    %w[data-name data-search data-category data-brand data-price data-band data-rating].each do |attr|
      assert_includes card, attr, "kartu katalog kehilangan #{attr}"
    end
  end

  def test_catalog_json_berisi_seluruh_item
    payload = JSON.parse(File.read(site_path("assets", "catalog.json"), encoding: "utf-8"))
    assert_equal catalog.length, payload["count"]
    assert_equal catalog.length, payload["items"].length
    assert_equal "IDR", payload["currency"]
  end

  def test_halaman_merek_hanya_memuat_merek_terkait
    { "kawasaki" => "Kawasaki", "vixian" => "Vixian" }.each do |page, brand|
      html = read_page(page, "index.html")
      brands = html.scan(/data-brand="([^"]+)"/).flatten.uniq
      assert_equal [brand], brands, "halaman #{page} memuat merek lain: #{brands.join(', ')}"
    end
  end

  # --- sitemap -----------------------------------------------------------
  def test_sitemap_memuat_setiap_halaman_publik
    sitemap = File.read(site_path("sitemap.xml"), encoding: "utf-8")
    TestSupport::LOCALES.each do |locale|
      PAGES.each do |id|
        prefix = locale == "id" ? "" : "/#{locale}"
        path = id == "home" ? "#{prefix}/" : "#{prefix}/#{id}/"
        assert_includes sitemap, "#{BASEURL}#{path}</loc>", "sitemap kehilangan #{path}"
      end
    end
  end

  def test_sitemap_tidak_memuat_halaman_404
    refute_includes File.read(site_path("sitemap.xml"), encoding: "utf-8"), "404.html"
  end

  # --- anggaran ukuran ---------------------------------------------------
  def test_halaman_beranda_tetap_ringan
    size = File.size(site_path("index.html"))
    assert_operator size, :<, 120_000, "beranda membengkak jadi #{size} byte"
  end

  def test_tidak_ada_gambar_yang_lebih_besar_dari_200_kb
    besar = Dir[File.join(ROOT, "_site", "assets", "img", "**", "*.{webp,jpg,png}")]
            .select { |f| File.size(f) > 200 * 1024 }
            .map { |f| "#{File.basename(f)} (#{File.size(f) / 1024} KB)" }
    assert_empty besar, "gambar terlalu besar: #{besar.join(', ')}"
  end

  # Sitemap ditulis sendiri agar bisa memuat anotasi bahasa; plugin bawaan
  # tidak menuliskannya, dan tanpa itu Google tidak tahu kelima versi bahasa
  # adalah halaman yang sama.
  def test_sitemap_memuat_anotasi_bahasa
    sitemap = File.read(site_path("sitemap.xml"), encoding: "utf-8")
    blocks = sitemap.scan(%r{<url>.*?</url>}m)

    assert_equal TestSupport::LOCALES.length * PAGES.length, blocks.length,
                 "jumlah entri sitemap tidak sesuai"

    blocks.each do |block|
      langs = block.scan(/xhtml:link rel="alternate" hreflang="([^"]+)"/).flatten
      assert_equal 6, langs.length, "entri sitemap kurang anotasi bahasa"
      assert_includes langs, "x-default"
    end
  end

  def test_halaman_heritage_hanya_memuat_harley
    html = read_page("heritage", "index.html")
    brands = html.scan(/data-brand="([^"]+)"/).flatten.uniq
    assert_equal ["Harley-Davidson"], brands
    assert_equal 100, html.scan(/<article class="card"/).length
  end

  def test_garis_waktu_heritage_urut_menaik
    html = read_page("heritage", "index.html")
    years = html.scan(/timeline__years">(\d{4})/).flatten.map(&:to_i)
    assert_equal 11, years.length, "jumlah generasi mesin tidak sesuai"
    assert_equal years.sort, years, "garis waktu harus urut dari tahun tertua"
  end

  def test_halaman_404_memuat_kelima_bahasa
    html = read_page("404.html")
    payload = html[/id="notfound-i18n">(.*?)<\/script>/m, 1]
    refute_nil payload, "data terjemahan 404 tidak ditemukan"
    TestSupport::LOCALES.each do |locale|
      assert_includes payload, %("#{locale}":), "404 tidak memuat bahasa #{locale}"
    end
  end

  # Detail produk dikirim sebagai satu blok JSON, bukan <template> per kartu.
  # Cara lama menyumbang 55 persen berat halaman katalog padahal isinya tidak
  # pernah tampil tanpa JavaScript.
  def detail_payload(*parts)
    html = read_page(*parts)
    raw = html[%r{id="catalog-details">(.*?)</script>}m, 1]
    refute_nil raw, "blok JSON detail tidak ditemukan di #{parts.join('/')}"
    JSON.parse(raw)
  end

  def test_detail_produk_dikirim_sebagai_json
    payload = detail_payload("catalog", "index.html")
    assert_equal catalog.length, payload.length
    assert_equal catalog.map { |i| i["sku"] }.sort, payload.keys.sort
  end

  def test_tidak_ada_lagi_template_per_kartu
    all_pages.each do |path|
      html = File.read(path, encoding: "utf-8")
      refute_includes html, "data-detail-content",
                      "#{File.basename(File.dirname(path))} masih memakai <template> per kartu"
    end
  end

  def test_setiap_entri_detail_lengkap
    payload = detail_payload("catalog", "index.html")
    payload.each do |sku, data|
      %w[n k b i p r s st sp].each do |field|
        refute_nil data[field], "#{sku}: kolom #{field} hilang"
      end
      refute_empty data["sp"], "#{sku}: tanpa spesifikasi"
      data["sp"].each { |pair| assert_equal 2, pair.length }
      assert_includes %w[ok warn], data["st"], "#{sku}: nada stok tidak dikenal"
    end
  end

  def test_detail_heritage_membawa_atribusi_foto
    payload = detail_payload("heritage", "index.html")
    berkredit = payload.values.select { |d| d["c"] }
    assert_equal catalog.count { |i| i["credit"] }, berkredit.length

    berkredit.each do |data|
      %w[t a l u].each { |field| refute_empty data["c"][field].to_s }
    end
  end

  def test_detail_ikut_diterjemahkan
    id = detail_payload("catalog", "index.html")["HTZ-MOT-001"]
    ja = detail_payload("ja", "catalog", "index.html")["HTZ-MOT-001"]

    assert_equal id["n"], ja["n"], "nama produk tidak diterjemahkan"
    refute_equal id["k"], ja["k"], "keterangan kategori harus mengikuti bahasa"
    refute_equal id["sp"][0][0], ja["sp"][0][0], "nama spesifikasi harus mengikuti bahasa"
  end

  # Anggaran berat halaman. Katalog adalah halaman terberat karena memuat
  # seluruh item sekaligus.
  def test_halaman_katalog_tetap_dalam_anggaran
    size = File.size(site_path("catalog", "index.html"))
    assert_operator size, :<, 500_000,
                    "katalog membengkak jadi #{size / 1024} KB; periksa apakah markup per kartu bertambah"
  end
end
