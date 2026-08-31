# frozen_string_literal: true

require_relative "test_helper"

# Data terstruktur adalah satu-satunya cara mesin pencari mengetahui bahwa
# halaman ini memuat produk, lengkap dengan harga dan ketersediaannya. Ia tidak
# terlihat pengunjung, jadi kesalahannya bisa bertahan lama tanpa ketahuan.
class SchemaTest < Minitest::Test
  include TestSupport

  # Halaman yang memuat daftar produk, dan jumlah yang seharusnya dinyatakan.
  DAFTAR_PRODUK = { "catalog" => 231, "heritage" => 100, "kawasaki" => 18, "vixian" => 18 }.freeze
  TANPA_DAFTAR = %w[home gallery reserve].freeze
  BATAS_ENTRI = 20

  def setup
    skip "jalankan `rake build` lebih dulu" unless site_built?
  end

  def blocks(locale, id)
    File.read(page_path_for(locale, id), encoding: "utf-8")
        .scan(%r{<script type="application/ld\+json">(.*?)</script>}m)
        .flatten.map { |raw| JSON.parse(raw) }
  end

  def item_list(locale, id)
    blocks(locale, id).find { |b| b["@type"] == "ItemList" }
  end

  def test_seluruh_blok_json_ld_terurai_di_setiap_bahasa
    TestSupport::LOCALES.each do |locale|
      (DAFTAR_PRODUK.keys + TANPA_DAFTAR).each do |id|
        assert_operator blocks(locale, id).size, :>=, 2, "#{locale}/#{id}"
      end
    end
  end

  # Regresi: halaman heritage dengan seratus unit dan kedua halaman merek
  # tidak menyatakan produknya sama sekali; hanya katalog yang punya.
  def test_setiap_halaman_daftar_menyatakan_produknya
    TestSupport::LOCALES.each do |locale|
      DAFTAR_PRODUK.each do |id, jumlah|
        list = item_list(locale, id)

        refute_nil list, "#{locale}/#{id}: tidak ada ItemList"
        assert_equal jumlah, list["numberOfItems"], "#{locale}/#{id}"
      end
    end
  end

  def test_halaman_tanpa_daftar_produk_tidak_mengarang_daftar
    TANPA_DAFTAR.each do |id|
      assert_nil item_list("id", id), "#{id} seharusnya tidak punya ItemList"
    end
  end

  def test_daftar_dibatasi_agar_halaman_tidak_membengkak
    TestSupport::LOCALES.each do |locale|
      DAFTAR_PRODUK.each_key do |id|
        assert_operator item_list(locale, id)["itemListElement"].size, :<=, BATAS_ENTRI, "#{locale}/#{id}"
      end
    end
  end

  def test_setiap_entri_membawa_kolom_yang_dibutuhkan
    DAFTAR_PRODUK.each_key do |id|
      item_list("id", id)["itemListElement"].each do |entry|
        assert_equal "ListItem", entry["@type"]
        assert_kind_of Integer, entry["position"]

        produk = entry["item"]

        assert_equal "Product", produk["@type"]
        %w[name sku url image brand category offers].each do |kolom|
          refute_nil produk[kolom], "#{id}/#{produk["sku"]}: #{kolom} kosong"
        end
        assert_equal "Brand", produk.dig("brand", "@type")
      end
    end
  end

  def test_penawaran_menyatakan_harga_mata_uang_dan_ketersediaan
    harga_katalog = catalog.to_h { |item| [item["sku"], item["price"]] }

    DAFTAR_PRODUK.each_key do |id|
      item_list("id", id)["itemListElement"].each do |entry|
        offer = entry["item"]["offers"]

        assert_equal "Offer", offer["@type"]
        assert_equal "IDR", offer["priceCurrency"]
        assert_equal harga_katalog[entry["item"]["sku"]], offer["price"], entry["item"]["sku"]
        assert_match %r{\Ahttps://schema\.org/(InStock|PreOrder)\z}, offer["availability"]
      end
    end
  end

  # Bintang pada kartu adalah data contoh dan tidak ada ulasan di baliknya.
  # Menyatakannya sebagai penilaian sungguhan bisa memicu cuplikan kaya di
  # hasil pencarian atas dasar angka yang dikarang.
  def test_tidak_menyatakan_penilaian_yang_tidak_ada
    TestSupport::LOCALES.each do |locale|
      DAFTAR_PRODUK.each_key do |id|
        mentah = File.read(page_path_for(locale, id), encoding: "utf-8")

        refute_includes mentah, "aggregateRating", "#{locale}/#{id}"
        refute_includes mentah, '"review"', "#{locale}/#{id}"
      end
    end
  end

  def test_alamat_dan_gambar_menunjuk_berkas_yang_ada
    hilang = []
    TestSupport::LOCALES.each do |locale|
      DAFTAR_PRODUK.each_key do |id|
        item_list(locale, id)["itemListElement"].each do |entry|
          produk = entry["item"]
          gambar = produk["image"].split("github.io").last.sub("/htzl-motorcycle-club", "")
          hilang << produk["image"] unless File.exist?(site_path(gambar.sub(%r{\A/}, "")))

          assert_match %r{\Ahttps://}, produk["url"], "#{locale}/#{id}: alamat harus mutlak"
        end
      end
    end

    assert_empty hilang.uniq
  end

  def test_deep_link_menunjuk_produk_yang_ada
    sku = catalog.map { |item| item["sku"] }

    DAFTAR_PRODUK.each_key do |id|
      item_list("id", id)["itemListElement"].each do |entry|
        kode = entry["item"]["url"][/item=([A-Za-z0-9-]+)/, 1]

        assert_includes sku, kode, "#{id}: #{kode} tidak ada di katalog"
      end
    end
  end

  def test_kategori_ikut_diterjemahkan
    kategori = TestSupport::LOCALES.to_h do |locale|
      [locale, item_list(locale, "catalog")["itemListElement"].first["item"]["category"]]
    end

    assert_operator kategori.values.uniq.size, :>=, 4,
                    "kategori seharusnya mengikuti bahasa: #{kategori.inspect}"
  end
end
