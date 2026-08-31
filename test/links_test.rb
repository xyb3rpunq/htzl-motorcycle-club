# frozen_string_literal: true

require_relative "test_helper"

# Pemeriksaan kotak hitam atas situs yang sudah dibangun: tautan, anchor, dan
# atribut keamanannya, dilihat sebagaimana pengunjung dan mesin pencari
# melihatnya, tanpa tahu apa pun soal isi templatenya.
class LinksTest < Minitest::Test
  include TestSupport

  BASEURL = "/htzl-motorcycle-club"

  # Domain luar yang memang disengaja. Daftar ini sempit dengan sengaja:
  # tautan keluar yang tidak terdaftar hampir selalu sisa dari materi lain.
  # Sebelum tes ini ada, tiga kartu berita berjudul Kawasaki dan Vixian
  # mengantar pembaca ke ducati.com.
  ALLOWED_HOSTS = %w[
    xyb3rpunq.github.io
    github.com
    wa.me
    www.instagram.com
    x.com
    www.linkedin.com
    maps.google.com
    fonts.googleapis.com
    fonts.gstatic.com
    schema.org
    www.w3.org
  ].freeze

  def setup
    skip "jalankan `rake build` lebih dulu" unless site_built?
  end

  def pages
    @pages ||= Dir[File.join(ROOT, "_site", "**", "*.html")]
  end

  def each_page
    pages.each { |path| yield path.sub("#{ROOT}/_site/", ""), File.read(path, encoding: "utf-8") }
  end

  def anchors(html)
    html.scan(/<a\b[^>]*>/m)
  end

  def href_of(tag)
    tag[/href="([^"]*)"/, 1]
  end

  def resolves?(href)
    path = href.sub(BASEURL, "").split(/[#?]/).first.to_s
    return true if path.empty?

    target = File.join(ROOT, "_site", path.sub(%r{\A/}, ""))
    File.exist?(target) || File.exist?(File.join(target, "index.html"))
  end

  def test_setiap_anchor_menunjuk_id_yang_ada
    rusak = []
    each_page do |name, html|
      ids = html.scan(/\sid="([^"]+)"/).flatten
      anchors(html).each do |tag|
        href = href_of(tag).to_s
        next unless href.start_with?("#") && href.length > 1

        rusak << "#{name} -> #{href}" unless ids.include?(href[1..])
      end
    end

    assert_empty rusak.uniq
  end

  # id ganda memutus anchor dan membingungkan pembaca layar: keduanya menunjuk
  # elemen pertama saja.
  def test_tidak_ada_id_ganda_dalam_satu_halaman
    ganda = []
    each_page do |name, html|
      berulang = html.scan(/\sid="([^"]+)"/).flatten.tally.select { |_, n| n > 1 }.keys
      ganda << "#{name}: #{berulang.join(", ")}" unless berulang.empty?
    end

    assert_empty ganda
  end

  def test_tautan_ke_tab_baru_selalu_memakai_noopener
    bocor = []
    each_page do |name, html|
      anchors(html).each do |tag|
        bocor << "#{name} -> #{href_of(tag)}" if tag.include?('target="_blank"') && !tag.include?("noopener")
      end
    end

    assert_empty bocor.uniq
  end

  def test_tidak_ada_tautan_tanpa_alamat
    kosong = []
    each_page do |name, html|
      anchors(html).each do |tag|
        href = href_of(tag)
        next if href.nil?

        kosong << "#{name}: #{tag[0, 60]}" if href.strip.empty?
      end
    end

    assert_empty kosong.uniq
  end

  def test_tidak_ada_alamat_yang_tidak_terenkripsi
    tidak_aman = []
    each_page do |name, html|
      html.scan(%r{(?:href|src)="(http://[^"]+)"}).flatten.each { |url| tidak_aman << "#{name} -> #{url}" }
    end

    assert_empty tidak_aman.uniq
  end

  # Tes tautan yang sudah ada melewatkan alamat bertanda # atau ?, padahal
  # justru di situ deep link katalog berada.
  def test_tautan_bertanda_fragmen_atau_kueri_tetap_menuju_halaman_yang_ada
    putus = []
    each_page do |name, html|
      html.scan(%r{href="(#{Regexp.escape(BASEURL)}/[^"]*[#?][^"]*)"}).flatten.uniq.each do |href|
        putus << "#{name} -> #{href}" unless resolves?(href)
      end
    end

    assert_empty putus.uniq
  end

  def test_deep_link_katalog_menunjuk_produk_yang_ada
    sku = JSON.parse(
      File.read(site_path("catalog", "index.html"), encoding: "utf-8")[
        %r{<script type="application/json" id="catalog-details">(.*?)</script>}m, 1
      ]
    ).keys

    asing = []
    each_page do |name, html|
      html.scan(/href="[^"]*[?&]item=([A-Za-z0-9-]+)/).flatten.uniq.each do |kode|
        asing << "#{name} -> #{kode}" unless sku.include?(kode)
      end
    end

    assert_empty asing.uniq
  end

  def test_tautan_keluar_hanya_ke_domain_yang_disengaja
    asing = []
    each_page do |name, html|
      html.scan(%r{(?:href|src)="https://([^/"]+)}).flatten.uniq.each do |host|
        asing << "#{name} -> #{host}" unless ALLOWED_HOSTS.include?(host)
      end
    end

    assert_empty asing.uniq, "domain di luar daftar: #{asing.uniq.first(5).join(", ")}"
  end

  # --- kartu berita -------------------------------------------------------

  def news
    @news ||= data_file("news.yml")
  end

  # Berita di beranda adalah konten fiktif untuk dealer fiktif. Menautkannya ke
  # situs pabrikan sungguhan membuat judul bermerek sendiri mengantar pembaca
  # ke tempat lain, dan itu persis yang dulu terjadi.
  def test_berita_menautkan_halaman_sendiri
    news.each do |item|
      assert_match %r{\A/[a-z0-9/-]*/\z}, item["url"], "berita menautkan alamat luar: #{item["url"]}"
    end
  end

  def test_tautan_berita_menuju_halaman_yang_benar_benar_ada
    TestSupport::LOCALES.each do |locale|
      prefix = locale == "id" ? "" : "/#{locale}"

      news.each do |item|
        assert resolves?("#{prefix}#{item["url"]}"), "#{locale}#{item["url"]} tidak ada"
      end
    end
  end

  def test_kartu_berita_terender_dengan_awalan_bahasa
    TestSupport::LOCALES.each do |locale|
      html = File.read(page_path_for(locale, "home"), encoding: "utf-8")
      tautan = html.scan(/<a class="news-card[^>]*href="([^"]*)"/).flatten

      assert_equal news.size, tautan.size, locale

      prefix = locale == "id" ? "" : "/#{locale}"

      tautan.each_with_index do |href, i|
        assert_equal "#{BASEURL}#{prefix}#{news[i]["url"]}", href, locale
      end
    end
  end

  # Tanggal di masa depan membuat situs terlihat salah setel, dan tanggal yang
  # jauh tertinggal membuatnya terlihat terbengkalai.
  def test_tanggal_berita_masuk_akal
    news.each do |item|
      tanggal = item["date"]

      assert_kind_of Date, tanggal
      assert_operator tanggal, :<=, Date.today, "berita bertanggal masa depan: #{tanggal}"
    end
  end

  def test_setiap_berita_lengkap_dalam_kelima_bahasa
    news.each do |item|
      TestSupport::LOCALES.each do |locale|
        refute_nil item["title"][locale], "judul #{locale} kosong"
        refute_nil item["topic"][locale], "topik #{locale} kosong"
        refute_empty item["title"][locale].strip
      end
    end
  end
end
