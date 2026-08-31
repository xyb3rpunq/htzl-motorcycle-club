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
    @all_pages ||= Dir[File.join(ROOT, "_site", "**", "*.html")]
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

        assert_path_exists path, "halaman hilang: #{locale}/#{id}"
      end
    end
  end

  def test_jumlah_halaman_sesuai_perkiraan
    expected = (TestSupport::LOCALES.length * PAGES.length) + 1 # +1 untuk 404

    assert_equal expected, all_pages.length,
                 "jumlah halaman tidak sesuai: #{all_pages.length} bukan #{expected}"
  end

  def test_halaman_pendukung_terbentuk
    %w[404.html robots.txt sitemap.xml site.webmanifest .nojekyll assets/catalog.json].each do |file|
      assert_path_exists site_path(file), "berkas hilang: #{file}"
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
      html.scan(%r{(?:src|href)="(#{Regexp.escape(BASEURL)}/[^"#?]+)"}).flatten.uniq.each do |url|
        target = site_path(url.sub(BASEURL, "").sub(%r{\A/}, ""))
        missing << "#{File.basename(path)} -> #{url}" unless File.exist?(target) || File.directory?(target)
      end
    end

    assert_empty missing.uniq.first(10), "aset tidak ditemukan: #{missing.uniq.first(10).join(", ")}"
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

    assert_empty tanpa_alt.uniq, "gambar tanpa atribut alt di: #{tanpa_alt.uniq.join(", ")}"
    assert_empty tanpa_dimensi.uniq, "gambar tanpa width/height di: #{tanpa_dimensi.uniq.join(", ")}"
  end

  def test_semua_ikon_yang_dipakai_terdefinisi_di_sprite
    html = read_page("catalog", "index.html")
    defined_ids = html.scan(/<symbol id="(i-[a-z0-9-]+)"/).flatten.uniq

    refute_empty defined_ids, "sprite ikon tidak ditemukan"

    all_pages.each do |path|
      used = File.read(path, encoding: "utf-8").scan(/<use href="#(i-[a-z0-9-]+)"/).flatten.uniq
      missing = used - defined_ids

      assert_empty missing, "#{File.basename(File.dirname(path))} memakai ikon tak terdefinisi: #{missing.join(", ")}"
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
    card = html[%r{<article class="card" data-item.*?</article>}m]

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

      assert_equal [brand], brands, "halaman #{page} memuat merek lain: #{brands.join(", ")}"
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

    assert_empty besar, "gambar terlalu besar: #{besar.join(", ")}"
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
    assert_equal 100, html.scan('<article class="card"').length
  end

  def test_garis_waktu_heritage_urut_menaik
    html = read_page("heritage", "index.html")
    years = html.scan(/timeline__years">(\d{4})/).flatten.map(&:to_i)

    assert_equal 11, years.length, "jumlah generasi mesin tidak sesuai"
    assert_equal years.sort, years, "garis waktu harus urut dari tahun tertua"
  end

  def test_halaman_404_memuat_kelima_bahasa
    html = read_page("404.html")
    payload = html[%r{id="notfound-i18n">(.*?)</script>}m, 1]

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

    refute_nil raw, "blok JSON detail tidak ditemukan di #{parts.join("/")}"
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

  # --- metadata berbagi --------------------------------------------------
  def test_setiap_halaman_punya_gambar_berbagi_sendiri
    harapan = {
      "home" => "og-image.jpg", "catalog" => "og-image.jpg",
      "kawasaki" => "og-kawasaki.jpg", "vixian" => "og-vixian.jpg",
      "heritage" => "og-heritage.jpg", "gallery" => "og-gallery.jpg",
      "reserve" => "og-reserve.jpg"
    }

    TestSupport::LOCALES.each do |locale|
      harapan.each do |id, file|
        html = File.read(page_path_for(locale, id), encoding: "utf-8")
        og = html[/<meta property="og:image" content="([^"]+)"/, 1]

        assert_includes og.to_s, file, "#{locale}/#{id}: gambar berbagi salah"
      end
    end
  end

  def test_berkas_gambar_berbagi_ada_dan_wajar
    %w[og-image og-kawasaki og-vixian og-heritage og-gallery og-reserve].each do |name|
      path = File.join(ROOT, "assets", "img", "#{name}.jpg")

      assert_path_exists path, "gambar berbagi hilang: #{name}.jpg"
      assert_operator File.size(path), :<, 300 * 1024, "#{name}.jpg terlalu besar"
    end
  end

  # Regresi: tanggal berita sempat tampil dalam Bahasa Inggris di kelima
  # bahasa karena memakai filter `date` bawaan Liquid.
  def test_tanggal_berita_mengikuti_bahasa_halaman
    hasil = TestSupport::LOCALES.to_h do |locale|
      html = File.read(page_path_for(locale, "home"), encoding: "utf-8")
      [locale, html[%r{<time datetime="[^"]+">([^<]+)</time>}, 1]]
    end

    hasil.each { |locale, text| refute_nil text, "#{locale}: tanggal berita tidak ditemukan" }

    # Jepang dan Mandarin memakai penulisan angka yang sama, jadi yang diuji
    # adalah bahwa tanggalnya tidak seragam di semua bahasa.
    assert_operator hasil.values.uniq.length, :>=, 4,
                    "tanggal seharusnya mengikuti bahasa, bukan seragam"
    assert_includes hasil["id"], "Mei"
    assert_includes hasil["en"], "May"
    assert_includes hasil["ru"], "мая"
    assert_includes hasil["ja"], "年"
    assert_includes hasil["zh"], "年"
  end

  # --- pencarian dan gambar responsif -------------------------------------

  def catalog_cards
    @catalog_cards ||= read_page("catalog", "index.html")
                       .scan(%r{<article class="card".*?</article>}m)
  end

  def search_blobs
    @search_blobs ||= catalog_cards.filter_map { |card| card[/data-search="([^"]*)"/, 1] }
  end

  # Nilai spesifikasi dulu tidak ikut diindeks, sehingga mengetik "Brembo" atau
  # "Cordura" tidak menemukan apa pun padahal produknya ada di katalog.
  def test_pencarian_mencakup_nilai_spesifikasi
    assert_equal catalog.size, search_blobs.size

    kosong = []
    catalog.each_with_index do |item, index|
      blob = search_blobs[index]
      item["specs"].each_value do |value|
        value.to_s.scan(/[[:alnum:]]{5,}/).each do |kata|
          kosong << "#{item["sku"]}: #{kata}" unless blob.include?(kata.downcase)
        end
      end
    end

    assert_empty kosong.first(10)
  end

  def test_kata_kunci_spesifikasi_menemukan_produk
    %w[brembo cordura titanium waterproof sintered ohlins].each do |kata|
      hasil = search_blobs.count { |blob| blob.include?(kata) }

      assert_operator hasil, :>=, 1, "\"#{kata}\" tidak menemukan apa pun"
    end
  end

  def test_indeks_pencarian_tidak_memuat_kata_kembar
    search_blobs.each do |blob|
      kata = blob.split

      assert_equal kata.uniq, kata, "indeks memuat kata kembar: #{blob[0, 60]}"
    end
  end

  def test_kartu_berfoto_menawarkan_beberapa_ukuran_gambar
    berfoto = catalog_cards.select { |card| card.include?(".webp") }

    refute_empty berfoto

    berfoto.each do |card|
      assert_includes card, "srcset=", "kartu tanpa srcset"
      assert_includes card, "sizes=", "kartu tanpa sizes"
    end
  end

  def test_setiap_kandidat_srcset_mengarah_ke_berkas_yang_ada
    kandidat = read_page("catalog", "index.html").scan(/srcset="([^"]*)"/).flatten
                                                 .flat_map { |set| set.split(",") }
                                                 .map { |entry| entry.strip.split(/\s+/).first }
                                                 .uniq

    refute_empty kandidat

    hilang = kandidat.reject { |url| File.exist?(site_path(url.sub(BASEURL, "").sub(%r{\A/}, ""))) }

    assert_empty hilang
  end

  # Dialog memakai berkas penuh, jadi varian kecil tidak boleh bocor ke sana.
  def test_json_detail_memakai_berkas_penuh
    json = JSON.parse(read_page("catalog", "index.html")[
      %r{<script type="application/json" id="catalog-details">(.*?)</script>}m, 1
    ])
    varian = json.each_value.select { |entry| entry["i"] =~ /-(384|640)\.webp\z/ }

    assert_empty(varian.map { |entry| entry["i"] })

    json.each_value do |entry|
      assert_operator entry["w"].to_i, :>, 0
      assert_operator entry["h"].to_i, :>, 0
    end
  end

  # --- prioritas gambar ---------------------------------------------------

  def images_in(html)
    html.scan(/<img[^>]*>/m)
  end

  # Banner dulu dipasang lewat background-image. Peramban baru menemukan gambar
  # semacam itu setelah CSS diurai dan tata letak dihitung, padahal ia elemen
  # terbesar di layar pertama.
  def test_banner_bukan_lagi_background_image
    %w[heritage gallery kawasaki vixian].each do |page|
      html = read_page(page, "index.html")

      refute_includes html, "background-image:url", "#{page}: banner masih background-image"
      assert_includes html, "page-banner__img", "#{page}: banner tanpa gambar"
    end
  end

  def test_banner_dimuat_segera_dan_diprioritaskan
    %w[heritage gallery kawasaki vixian].each do |page|
      banner = read_page(page, "index.html")[/<img class="page-banner__img"[^>]*>/m]

      refute_nil banner, page
      assert_includes banner, 'loading="eager"', page
      assert_includes banner, 'fetchpriority="high"', page
      assert_includes banner, 'srcset="', page
      assert_includes banner, 'sizes="', page
    end
  end

  # Banner murni dekoratif: judul halaman sudah ada sebagai teks di atasnya.
  def test_banner_tidak_menambah_kebisingan_untuk_pembaca_layar
    banner = read_page("heritage", "index.html")[/<img class="page-banner__img"[^>]*>/m]

    assert_includes banner, 'alt=""'
  end

  def test_hero_beranda_dikirim_dalam_beberapa_ukuran
    hero = read_page("index.html")[%r{<img[^>]*/assets/img/hero/[^>]*>}m]

    refute_nil hero
    assert_includes hero, "srcset="
    assert_includes hero, 'sizes="100vw"'
    assert_includes hero, 'fetchpriority="high"'
  end

  # Terlalu banyak gambar segera justru merebut bandwidth dari elemen LCP.
  # Diukur: empat kartu segera membuat halaman heritage 396 ms lebih lambat.
  def test_gambar_segera_dibatasi_dua_per_halaman
    all_pages.each do |path|
      eager = images_in(File.read(path, encoding: "utf-8")).count { |img| img.include?('loading="eager"') }

      assert_operator eager, :<=, 2, "#{File.basename(File.dirname(path))}: #{eager} gambar eager"
    end
  end

  def test_hanya_satu_gambar_berprioritas_tinggi_per_halaman
    all_pages.each do |path|
      high = images_in(File.read(path, encoding: "utf-8")).count { |img| img.include?('fetchpriority="high"') }

      assert_operator high, :<=, 1, "#{path}: #{high} gambar fetchpriority high"
    end
  end

  # Kartu pertama halaman katalog adalah elemen LCP-nya, jadi ia tidak boleh
  # lazy. Di heritage dan merek, elemen LCP adalah banner.
  def test_kartu_pertama_katalog_dimuat_segera
    first = read_page("catalog", "index.html")[%r{<article class="card".*?</article>}m]

    assert_includes first, 'loading="eager"'
    assert_includes first, 'fetchpriority="high"'
  end

  def test_kartu_pertama_heritage_dan_merek_tetap_lazy
    %w[heritage kawasaki].each do |page|
      first = read_page(page, "index.html")[%r{<article class="card".*?</article>}m]

      assert_includes first, 'loading="lazy"', page
    end
  end

  def test_semua_kandidat_srcset_di_seluruh_halaman_ada
    hilang = all_pages.flat_map do |path|
      File.read(path, encoding: "utf-8").scan(/srcset="([^"]*)"/).flatten
          .flat_map { |set| set.split(",") }
          .map { |entry| entry.strip.split(/\s+/).first }
          .reject { |url| File.exist?(site_path(url.sub(BASEURL, "").sub(%r{\A/}, ""))) }
    end.uniq

    assert_empty hilang
  end
end
