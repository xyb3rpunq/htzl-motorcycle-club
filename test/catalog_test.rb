# frozen_string_literal: true

require_relative "test_helper"

# Menguji setiap fungsi publik di HTZL::Catalog.
class CatalogTest < Minitest::Test
  include TestSupport

  # --- build -------------------------------------------------------------
  def test_build_menghasilkan_lebih_dari_seratus_item
    assert_operator catalog.length, :>=, 100, "katalog wajib berisi minimal 100 item"
  end

  def test_build_bersifat_deterministik
    assert_equal HTZL::Catalog.build, HTZL::Catalog.build,
                 "build harus menghasilkan data identik pada tiap pemanggilan"
  end

  def test_setiap_item_punya_kolom_wajib
    wajib = %w[name slug category category_label subcategory brand price price_band
               badge stock rating blurb specs blurb_type]
    catalog.each do |item|
      wajib.each { |key| assert item.key?(key), "#{item['name']} kehilangan kolom #{key}" }
    end
  end

  def test_sku_unik_dan_berformat_benar
    skus = catalog.map { |i| i["sku"] }
    assert_equal skus.length, skus.uniq.length, "SKU tidak boleh kembar"
    skus.each { |sku| assert_match(/\AHTZ-[A-Z]{3}-\d{3}\z/, sku) }
  end

  def test_slug_unik_dan_aman_untuk_url
    slugs = catalog.map { |i| i["slug"] }
    assert_equal slugs.length, slugs.uniq.length
    slugs.each { |slug| assert_match(/\A[a-z0-9-]+\z/, slug) }
  end

  def test_harga_selalu_bilangan_positif
    catalog.each do |item|
      assert_kind_of Integer, item["price"]
      assert_operator item["price"], :>, 0, "#{item['name']} punya harga tidak wajar"
    end
  end

  def test_harga_coret_selalu_lebih_tinggi_dari_harga_jual
    catalog.select { |i| i["price_old"] }.each do |item|
      assert_operator item["price_old"], :>, item["price"],
                      "#{item['name']}: harga coret harus lebih tinggi"
    end
  end

  def test_rating_dalam_rentang_wajar
    catalog.each do |item|
      assert_includes 4.0..5.0, item["rating"], "#{item['name']} punya rating di luar rentang"
    end
  end

  def test_setiap_item_punya_gambar_atau_ikon
    catalog.each do |item|
      assert item["image"] || item["icon"], "#{item['name']} tidak punya gambar maupun ikon"
    end
  end

  def test_berkas_gambar_motor_benar_benar_ada
    catalog.select { |i| i["image"] }.each do |item|
      path = File.join(ROOT, item["image"].sub(%r{\A/}, ""))
      assert File.exist?(path), "gambar hilang: #{item['image']}"
    end
  end

  def test_kategori_terdaftar_di_konstanta
    catalog.each do |item|
      assert_includes HTZL::Catalog::CATEGORIES.keys, item["category"]
    end
  end

  def test_setiap_kategori_terisi
    HTZL::Catalog::CATEGORIES.each_key do |key|
      count = catalog.count { |i| i["category"] == key }
      assert_operator count, :>, 0, "kategori #{key} kosong"
    end
  end

  def test_motor_punya_tiga_trim_per_model
    motors = catalog.select { |i| i["category"] == "motor" }
    assert_equal HTZL::Catalog::BIKES.length * HTZL::Catalog::TRIMS.length, motors.length
    %w[Standard S SP].each do |trim|
      assert_equal HTZL::Catalog::BIKES.length, motors.count { |i| i["trim"] == trim }
    end
  end

  def test_trim_lebih_tinggi_selalu_lebih_mahal
    HTZL::Catalog::BIKES.each do |bike|
      variants = catalog.select { |i| i["name"].start_with?(bike[:name]) && i["category"] == "motor" }
      standard = variants.find { |i| i["trim"] == "Standard" }
      sp = variants.find { |i| i["trim"] == "SP" }
      assert_operator sp["price"], :>, standard["price"], "#{bike[:name]}: SP harus lebih mahal dari Standard"
    end
  end

  def test_spesifikasi_tidak_pernah_kosong
    catalog.each do |item|
      refute_empty item["specs"], "#{item['name']} tidak punya spesifikasi"
      item["specs"].each do |key, value|
        refute_empty key.to_s.strip
        refute_empty value.to_s.strip
      end
    end
  end

  # --- rupiah ------------------------------------------------------------
  def test_rupiah_memakai_pemisah_ribuan_indonesia
    assert_equal "Rp 45.000.000", HTZL::Catalog.rupiah(45_000_000)
    assert_equal "Rp 285.000", HTZL::Catalog.rupiah(285_000)
    assert_equal "Rp 750", HTZL::Catalog.rupiah(750)
    assert_equal "Rp 0", HTZL::Catalog.rupiah(0)
  end

  def test_rupiah_menangani_nilai_negatif_dan_nil
    assert_equal "-Rp 1.500", HTZL::Catalog.rupiah(-1_500)
    assert_equal "-", HTZL::Catalog.rupiah(nil)
  end

  # --- slugify -----------------------------------------------------------
  def test_slugify_membersihkan_karakter_khusus
    assert_equal "kawasaki-x56-sp", HTZL::Catalog.slugify("Kawasaki x56 SP")
    assert_equal "rantai-gir", HTZL::Catalog.slugify("Rantai & Gir")
    assert_equal "oli-mesin-10w-40", HTZL::Catalog.slugify("  Oli Mesin 10W-40  ")
    assert_equal "", HTZL::Catalog.slugify("!!!")
  end

  # --- spec_summary ------------------------------------------------------
  def test_spec_summary_membatasi_jumlah_dan_memakai_pemisah
    specs = { "Bahan" => "Kulit", "Berat" => "1 kg", "Ukuran" => "L", "Warna" => "Hitam" }
    assert_equal "Bahan: Kulit | Berat: 1 kg", HTZL::Catalog.spec_summary(specs, 2)
    assert_equal 3, HTZL::Catalog.spec_summary(specs).split(" | ").length
  end

  def test_spec_summary_aman_untuk_masukan_kosong
    assert_equal "", HTZL::Catalog.spec_summary(nil)
    assert_equal "", HTZL::Catalog.spec_summary({})
  end

  # --- price_band --------------------------------------------------------
  def test_price_band_memetakan_setiap_batas_dengan_benar
    assert_equal "under-500k",   HTZL::Catalog.price_band(75_000)
    assert_equal "under-500k",   HTZL::Catalog.price_band(499_999)
    assert_equal "500k-2jt",     HTZL::Catalog.price_band(500_000)
    assert_equal "2jt-10jt",     HTZL::Catalog.price_band(2_000_000)
    assert_equal "10jt-50jt",     HTZL::Catalog.price_band(10_000_000)
    assert_equal "50jt-500jt",    HTZL::Catalog.price_band(50_000_000)
    assert_equal "50jt-500jt",    HTZL::Catalog.price_band(499_999_999)
    assert_equal "di-atas-500jt", HTZL::Catalog.price_band(500_000_000)
    assert_equal "di-atas-500jt", HTZL::Catalog.price_band(4_500_000_000)
  end

  def test_price_band_setiap_item_konsisten_dengan_harganya
    catalog.each do |item|
      assert_equal HTZL::Catalog.price_band(item["price"]), item["price_band"],
                   "#{item['name']}: rentang harga tidak sesuai"
    end
  end

  # --- stats -------------------------------------------------------------
  def test_stats_menghitung_total_dan_rentang_harga
    stats = HTZL::Catalog.stats(catalog)
    assert_equal catalog.length, stats["total"]
    assert_equal catalog.map { |i| i["price"] }.min, stats["min_price"]
    assert_equal catalog.map { |i| i["price"] }.max, stats["max_price"]
    assert_equal catalog.length, stats["categories"].values.sum
  end

  # --- berkas hasil seed -------------------------------------------------
  def test_data_catalog_yml_sinkron_dengan_generator
    skip "jalankan `rake seed` lebih dulu" unless File.exist?(File.join(ROOT, "_data", "catalog.yml"))
    assert_equal catalog, data_file("catalog.yml"),
                 "_data/catalog.yml sudah usang, jalankan `rake seed`"
  end

  def test_catalog_meta_sinkron_dengan_katalog
    skip "jalankan `rake seed` lebih dulu" unless File.exist?(File.join(ROOT, "_data", "catalog_meta.yml"))
    meta = data_file("catalog_meta.yml")
    assert_equal catalog.length, meta["total"]
    assert_equal catalog.map { |i| i["brand"] }.uniq.sort, meta["brands"]
    assert_equal catalog.length, meta["categories"].sum { |c| c["count"] }
  end

  # Kontrak lintas bahasa: berkas fixture yang sama juga dibaca oleh
  # test/js/reserve.test.mjs. Ruby memformat harga saat build, JavaScript
  # memformatnya lagi saat pengunjung mengubah jumlah pesanan, dan keduanya
  # harus menghasilkan teks yang persis sama.
  def test_rupiah_cocok_dengan_kontrak_bersama_javascript
    fixture = JSON.parse(File.read(File.join(ROOT, "test", "fixtures", "rupiah.json"), encoding: "utf-8"))

    (fixture["cases"] + fixture["negative"]).each do |input, expected|
      assert_equal expected, HTZL::Catalog.rupiah(input),
                   "rupiah(#{input}) berbeda dari kontrak di test/fixtures/rupiah.json"
    end
  end
end
