# frozen_string_literal: true

require_relative "test_helper"

# Filter Liquid diuji tanpa menjalankan Jekyll. Konteks Liquid dipalsukan
# dengan objek sederhana supaya filter yang membaca site.data tetap bisa diuji.
require_relative "../lib/htzl/filters"

class FiltersTest < Minitest::Test
  include TestSupport

  FakeSite = Struct.new(:data, :config)

  class FakeContext
    attr_reader :registers

    def initialize(site)
      @registers = { site: site }
    end
  end

  # Kelas uji yang menyertakan kedua modul filter, meniru strainer Liquid.
  class Subject
    def initialize(context)
      @context = context
    end
  end

  def setup
    site = FakeSite.new(
      { "i18n" => { "en" => i18n("en"), "id" => i18n("id"), "terms" => terms } },
      { "baseurl" => "/htzl-motorcycle-club" }
    )
    @subject = Subject.new(FakeContext.new(site))
    @subject.extend(HTZL::Filters)
    @subject.extend(HTZL::I18nFilters)
  end

  # --- rupiah ------------------------------------------------------------
  def test_rupiah
    assert_equal "Rp 45.000.000", @subject.rupiah(45_000_000)
    assert_equal "-", @subject.rupiah(nil)
  end

  # --- rupiah_short ------------------------------------------------------
  def test_rupiah_short_meringkas_tiap_satuan
    assert_equal "Rp 45 jt", @subject.rupiah_short(45_000_000)
    assert_equal "Rp 1,5 jt", @subject.rupiah_short(1_500_000)
    assert_equal "Rp 285 rb", @subject.rupiah_short(285_000)
    assert_equal "Rp 750", @subject.rupiah_short(750)
    assert_equal "Rp 1,2 M", @subject.rupiah_short(1_200_000_000)
    assert_equal "-", @subject.rupiah_short(nil)
  end

  # --- htzl_slug ---------------------------------------------------------
  def test_htzl_slug
    assert_equal "vixian-mt-1260", @subject.htzl_slug("Vixian MT-1260")
  end

  # --- discount_percent --------------------------------------------------
  def test_discount_percent_menghitung_potongan
    assert_equal 20, @subject.discount_percent({ "price" => 800_000, "price_old" => 1_000_000 })
    assert_nil @subject.discount_percent({ "price" => 800_000, "price_old" => nil })
    assert_nil @subject.discount_percent({ "price" => 800_000, "price_old" => 700_000 })
  end

  # --- star_bar ----------------------------------------------------------
  def test_star_bar_membulatkan_rating
    assert_equal "★★★★★", @subject.star_bar(4.8)
    assert_equal "★★★★☆", @subject.star_bar(4.2)
    assert_equal "★★★★★", @subject.star_bar(9.0), "rating di atas 5 tetap dibatasi lima bintang"
    assert_equal "☆☆☆☆☆", @subject.star_bar(-1)
  end

  # --- whatsapp_link -----------------------------------------------------
  def test_whatsapp_link_membersihkan_nomor_dan_menyandi_pesan
    url = @subject.whatsapp_link("+62 812-3456-7890", "Halo HTZL, pesan Kawasaki x56")
    assert url.start_with?("https://wa.me/6281234567890?text="), "nomor harus dibersihkan"
    refute_includes url, " ", "spasi wajib tersandi"
    assert_includes url, "Halo%20HTZL"
  end

  def test_whatsapp_link_menyandi_karakter_non_latin
    url = @subject.whatsapp_link("6281", "Здравствуйте")
    assert_includes url, "%D0%97", "huruf Kiril harus tersandi UTF-8"
  end

  # --- spec_line ---------------------------------------------------------
  def test_spec_line
    assert_equal "Bahan: Kulit", @subject.spec_line({ "Bahan" => "Kulit", "Berat" => "1 kg" }, 1)
  end

  # --- search_blob -------------------------------------------------------
  def test_search_blob_menggabungkan_kolom_pencarian_dalam_huruf_kecil
    blob = @subject.search_blob({
      "name" => "Kawasaki x56", "brand" => "Kawasaki",
      "subcategory" => "Superbike", "category_label" => "Motor", "sku" => "HTZ-MOT-001"
    })
    assert_equal "kawasaki x56 kawasaki superbike motor htz-mot-001", blob
  end

  # --- t -----------------------------------------------------------------
  def test_t_mengambil_string_lewat_jalur_bertitik
    assert_equal i18n("en")["catalog"]["title"], @subject.t("catalog.title", "en")
    assert_equal i18n("id")["nav"]["home"], @subject.t("nav.home", "id")
  end

  def test_t_mengembalikan_kunci_bila_tidak_ditemukan
    assert_equal "tidak.ada", @subject.t("tidak.ada", "en")
    assert_equal "nav.home", @subject.t("nav.home", "xx")
  end

  # --- term --------------------------------------------------------------
  def test_term_menerjemahkan_lewat_kamus
    assert_equal "Helmets", @subject.term("Helm", "subcategory", "en")
    assert_equal "Material", @subject.term("Bahan", "spec_key", "en")
  end

  def test_term_mengembalikan_teks_asli_untuk_bahasa_dasar
    assert_equal "Helm", @subject.term("Helm", "subcategory", "id")
  end

  def test_term_jatuh_kembali_bila_terjemahan_belum_ada
    assert_equal "Istilah Baru", @subject.term("Istilah Baru", "subcategory", "en")
    assert_nil @subject.term(nil, "subcategory", "en")
  end

  # --- fill --------------------------------------------------------------
  def test_fill_mengganti_placeholder
    assert_equal "Superbike 1362 cc",
                 @subject.fill("%{type} %{cc} cc", "type", "Superbike", "cc", 1362)
  end

  def test_fill_membiarkan_placeholder_yang_tidak_diisi
    assert_equal "%{type} 1362 cc", @subject.fill("%{type} %{cc} cc", "cc", 1362)
  end

  # --- locale_url --------------------------------------------------------
  def test_locale_url_menambahkan_baseurl_dan_awalan_bahasa
    assert_equal "/htzl-motorcycle-club/catalog/", @subject.locale_url("/catalog/")
    assert_equal "/htzl-motorcycle-club/en/catalog/", @subject.locale_url("/catalog/", "en")
    assert_equal "/htzl-motorcycle-club/catalog/", @subject.locale_url("/catalog/", "id")
  end

  # --- Measures: pelokalan angka dan satuan ------------------------------
  def test_pemisah_ribuan_mengikuti_kebiasaan_tiap_bahasa
    assert_equal "1,362 cc", HTZL::Measures.localize("1.362 cc", "en")
    assert_equal "1,362 cc", HTZL::Measures.localize("1.362 cc", "zh")
    assert_equal "1,362 cc", HTZL::Measures.localize("1.362 cc", "ja")
    assert_equal "1362 cc",  HTZL::Measures.localize("1.362 cc", "ru")
  end

  def test_pemisah_desimal_ikut_dibalik
    assert_equal "0.8 mm", HTZL::Measures.localize("0,8 mm", "en")
    assert_equal "0,8 mm", HTZL::Measures.localize("0,8 mm", "ru")
  end

  # Regresi: kode standar seperti "ECE 22.06" dan "DOT 5.1" memakai titik yang
  # BUKAN pemisah ribuan, jadi tidak boleh ikut diubah.
  def test_kode_standar_tidak_ikut_diformat_ulang
    ["ECE 22.06", "DOT 5.1", "120/70 ZR17", "1:100", "525", "58W"].each do |value|
      assert_equal value, HTZL::Measures.localize(value, "en"),
                   "#{value} seharusnya tidak berubah"
    end
  end

  def test_kata_satuan_diterjemahkan
    assert_equal "12 months", HTZL::Measures.localize("12 bulan", "en")
    assert_equal "12 个月",   HTZL::Measures.localize("12 bulan", "zh")
    assert_equal "2 hours",   HTZL::Measures.localize("2 jam", "en")
    assert_equal "120 links", HTZL::Measures.localize("120 mata", "en")
    assert_equal "1 litres",  HTZL::Measures.localize("1 liter", "en")
  end

  def test_nama_diri_dibiarkan_apa_adanya
    assert_equal "Knucklehead", HTZL::Measures.localize("Knucklehead", "ja")
    assert_equal "Cordura 600D", HTZL::Measures.localize("Cordura 600D", "zh")
    assert_equal "Panhead", HTZL::Measures.localize("Panhead", "ru")
  end

  # Frasa yang memuat kata Indonesia harus diserahkan ke kamus, bukan
  # diterjemahkan sebagian.
  def test_frasa_bukan_satuan_dikembalikan_nil
    assert_nil HTZL::Measures.localize("Kulit sapi 1,2 mm", "en")
    assert_nil HTZL::Measures.localize("Rigid, garpu Springer", "en")
    assert_nil HTZL::Measures.localize(nil, "en")
  end

  # --- term untuk nilai spesifikasi --------------------------------------
  def test_term_menggabungkan_lapisan_otomatis_dan_kamus
    assert_equal "1,362 cc", @subject.term("1.362 cc", "spec_value", "en")
    assert_equal "1.362 cc", @subject.term("1.362 cc", "spec_value", "id"),
                 "bahasa dasar tidak diubah"
  end
end
