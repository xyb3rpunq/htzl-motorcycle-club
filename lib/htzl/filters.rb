# frozen_string_literal: true

require_relative "catalog"
require_relative "locales"

module HTZL
  # Filter Liquid khusus HTZL. Berperan seperti helper di app/helpers pada Rails:
  # pemformatan yang berulang di template dikumpulkan di satu tempat.
  #
  # Modul ini sengaja bebas dari Jekyll supaya bisa diuji langsung dengan
  # Minitest (lihat test/filters_test.rb). Pendaftaran ke Liquid dilakukan
  # oleh adapter tipis di _plugins/.
  module Filters
    # 45_000_000 -> "Rp 45.000.000"
    def rupiah(value)
      HTZL::Catalog.rupiah(value)
    end

    # 45_000_000 -> "Rp 45 jt" | 285_000 -> "Rp 285 rb"
    def rupiah_short(value)
      return "-" if value.nil?

      n = value.to_i
      if n >= 1_000_000_000
        format("Rp %s M", trim_decimal(n / 1_000_000_000.0))
      elsif n >= 1_000_000
        format("Rp %s jt", trim_decimal(n / 1_000_000.0))
      elsif n >= 1_000
        format("Rp %s rb", trim_decimal(n / 1_000.0))
      else
        HTZL::Catalog.rupiah(n)
      end
    end

    # "Kawasaki x56 SP" -> "kawasaki-x56-sp"
    def htzl_slug(text)
      HTZL::Catalog.slugify(text)
    end

    # Persentase potongan harga, dibulatkan ke bawah. Nil kalau tidak diskon.
    def discount_percent(item)
      old = item["price_old"]
      now = item["price"]
      return nil if old.nil? || now.nil? || old.to_i <= now.to_i

      ((old.to_i - now.to_i) * 100 / old.to_i)
    end

    # 4.6 -> "★★★★★" (dibulatkan, dibatasi lima bintang)
    def star_bar(rating)
      full = rating.to_f.round
      full = 5 if full > 5
      full = 0 if full.negative?
      ("★" * full) + ("☆" * (5 - full))
    end

    # Susun deep link WhatsApp lengkap dengan pesan siap kirim.
    def whatsapp_link(number, message)
      "https://wa.me/#{number.to_s.gsub(/\D/, '')}?text=#{escape_component(message.to_s)}"
    end

    # Ringkas hash spesifikasi jadi satu baris.
    def spec_line(specs, limit = 3)
      HTZL::Catalog.spec_summary(specs, limit.to_i)
    end

    # Teks pencarian yang dinormalisasi untuk atribut data-search.
    def search_blob(item)
      [item["name"], item["brand"], item["subcategory"], item["category_label"], item["sku"]]
        .compact.join(" ").downcase
    end

    private

    def trim_decimal(float)
      rounded = float.round(1)
      rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s.tr(".", ",")
    end

    # Penyandian persen untuk komponen URL, termasuk karakter non-Latin.
    def escape_component(text)
      text.gsub(/[^a-zA-Z0-9\-_.~]/) do |char|
        char.bytes.map { |b| format("%%%02X", b) }.join
      end
    end
  end

  # Filter penerjemah. Membaca site.data lewat konteks Liquid.
  module I18nFilters
    # Cari string di _data/i18n/<lang>.yml lewat jalur bertitik.
    #   {{ 'catalog.title' | t: page.lang }}
    def t(key, lang)
      dict = site_data.dig("i18n", lang.to_s)
      return key if dict.nil?

      value = key.to_s.split(".").reduce(dict) { |acc, part| acc.is_a?(Hash) ? acc[part] : nil }
      value.nil? ? key : value
    end

    # Terjemahkan istilah katalog lewat kamus, jatuh kembali ke teks asli.
    #   {{ item.subcategory | term: 'subcategory', page.lang }}
    def term(text, kind, lang)
      return text if text.nil? || lang.to_s == HTZL::DEFAULT_LOCALE

      entry = site_data.dig("i18n", "terms", kind.to_s, text.to_s)
      entry.is_a?(Hash) && entry[lang.to_s] ? entry[lang.to_s] : text
    end

    # Isi placeholder gaya %{nama} pada string terjemahan.
    #   {{ template | fill: 'type', 'Superbike', 'cc', 1362 }}
    def fill(template, *pairs)
      result = template.to_s
      pairs.each_slice(2) { |key, value| result = result.gsub("%{#{key}}", value.to_s) }
      result
    end

    # Gabungkan baseurl situs dengan awalan bahasa dan path lokal.
    def locale_url(path, lang = nil)
      base = site_object.config["baseurl"].to_s
      prefix = lang.nil? ? "" : site_data.dig("i18n", lang.to_s, "prefix").to_s
      "#{base}#{prefix}#{path}"
    end

    private

    def site_object
      @context.registers[:site]
    end

    def site_data
      site_object.data
    end
  end
end
