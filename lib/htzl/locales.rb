# frozen_string_literal: true

module HTZL
  # Konfigurasi bahasa. Kode mengikuti ISO 639-1 supaya atribut hreflang valid
  # dan mesin pencari mengindeks tiap bahasa sebagai halaman terpisah.
  LOCALES = %w[id en zh ru ja].freeze
  DEFAULT_LOCALE = "id"

  # Cetak biru halaman. Satu entri menghasilkan lima halaman, satu per bahasa.
  BLUEPRINTS = [
    { id: "home", layout: "home", path: "", meta: "home_desc", nav: "home",
og: "og-image.jpg" },
    { id: "catalog", layout: "catalog", path: "catalog/", meta: "catalog_desc", nav: "catalog",
og: "og-image.jpg" },
    { id: "kawasaki", layout: "brand", path: "kawasaki/", meta: "kawasaki_desc", nav: "kawasaki", brand: "Kawasaki",
brand_key: "kawasaki", og: "og-kawasaki.jpg" },
    { id: "vixian", layout: "brand", path: "vixian/", meta: "vixian_desc", nav: "vixian", brand: "Vixian",
brand_key: "vixian", og: "og-vixian.jpg" },
    { id: "heritage", layout: "heritage", path: "heritage/", meta: "heritage_desc", nav: "heritage",
og: "og-heritage.jpg" },
    { id: "gallery",  layout: "gallery", path: "gallery/", meta: "gallery_desc", nav: "gallery",
og: "og-gallery.jpg" },
    { id: "reserve", layout: "reserve", path: "reserve/", meta: "reserve_desc", nav: "reserve",
og: "og-reserve.jpg" }
  ].freeze
end
