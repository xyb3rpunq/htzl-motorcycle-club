# frozen_string_literal: true

require "date"
require "digest"
require_relative "catalog"
require_relative "locales"

require_relative "image_sources"

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
      "https://wa.me/#{number.to_s.gsub(/\D/, "")}?text=#{escape_component(message.to_s)}"
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

    # Sidik jari sebuah skrip inline untuk Content-Security-Policy.
    #
    # Situs ini terbit di GitHub Pages, yang tidak bisa mengirim header HTTP
    # sendiri, jadi kebijakannya dinyatakan lewat <meta http-equiv>. Agar
    # script-src tetap ketat tanpa 'unsafe-inline', tiap skrip inline
    # diizinkan lewat sidik jarinya sendiri.
    #
    # Nilainya dihitung dari isi skrip persis seperti yang dikirim, jadi
    # templat harus menangkap isinya sekali lalu memakai tangkapan yang sama
    # untuk sidik jari dan untuk keluarannya.
    def csp_hash(script)
      digest = Digest::SHA256.digest(script.to_s)
      "sha256-#{[digest].pack("m0")}"
    end

    # Membuang kata kembar dari indeks pencarian.
    #
    # Blob pencarian menggabungkan nama, merek, kategori, dan seluruh nilai
    # spesifikasi, sehingga kata seperti "mm" atau "aluminium" muncul berkali
    # kali dalam satu kartu. Pencocokannya memeriksa tiap kata kunci sebagai
    # substring dan tidak peduli urutan, jadi pengulangan itu hanya menambah
    # berat halaman. Pada katalog penuh, ini memangkas sekitar 60 KB.
    def search_tokens(text)
      text.to_s.downcase.scan(/[[:alnum:]]+/).uniq.join(" ")
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

  # Pelokalan nilai spesifikasi yang berupa angka dan satuan.
  #
  # Nilai seperti "1.362 cc" tidak netral bahasa: Bahasa Indonesia memakai titik
  # sebagai pemisah ribuan, sehingga di Bahasa Inggris angka itu terbaca 1,362
  # (satu koma tiga). Modul ini menangani seluruh nilai berpola angka + satuan
  # secara otomatis, sehingga penambahan produk baru tidak perlu entri kamus.
  module Measures
    # Kata satuan Bahasa Indonesia beserta padanannya.
    UNITS = {
      "liter"  => { "en" => "litres",  "zh" => "升", "ru" => "л", "ja" => "L" },
      "bulan"  => { "en" => "months",  "zh" => "个月", "ru" => "мес.", "ja" => "か月" },
      "hari"   => { "en" => "days",    "zh" => "天", "ru" => "дней", "ja" => "日間" },
      "jam"    => { "en" => "hours",   "zh" => "小时",   "ru" => "часов",    "ja" => "時間" },
      "menit"  => { "en" => "minutes", "zh" => "分钟",   "ru" => "минут",    "ja" => "分" },
      "tahun"  => { "en" => "years",   "zh" => "年",     "ru" => "лет",      "ja" => "年" },
      "detik"  => { "en" => "seconds", "zh" => "秒",     "ru" => "секунд",   "ja" => "秒" },
      "mikron" => { "en" => "micron",  "zh" => "微米", "ru" => "мкм", "ja" => "ミクロン" },
      "mata"   => { "en" => "links",   "zh" => "节",     "ru" => "звеньев",  "ja" => "リンク" },
      "klik"   => { "en" => "clicks",  "zh" => "档",     "ru" => "щелчков",  "ja" => "クリック" },
      "sumbu"  => { "en" => "axis",    "zh" => "轴",     "ru" => "осей",     "ja" => "軸" },
      "inci"   => { "en" => "inches",  "zh" => "英寸", "ru" => "дюйма", "ja" => "インチ" },
      "pcs"    => { "en" => "pc",      "zh" => "件",     "ru" => "шт",       "ja" => "個" },
      "set"    => { "en" => "set",     "zh" => "套",     "ru" => "компл.",   "ja" => "セット" },
      "sampai" => { "en" => "to",      "zh" => "至",     "ru" => "до",       "ja" => "〜" },
      "dan"    => { "en" => "and",     "zh" => "和",     "ru" => "и",        "ja" => "・" },
      "per"    => { "en" => "per",     "zh" => "每",     "ru" => "на",       "ja" => "あたり" }
    }.freeze

    # Nama diri yang tidak diterjemahkan di bahasa mana pun: merek, standar
    # sertifikasi, kode material, dan nama generasi mesin.
    PROPER_NOUNS = %w[
      Brembo Ohlins Cordura Delrin Vibram Coolmax Pinlock GoPro Kevlar Stylema
      Photochromic Alcantara Gore-Tex
      CE DOT ECE SNI FIM API JASO EN ISO GL-5 MA2 SN SL DOT4 IP67 N95
      TPU EVA ABS PU PD CNC LED USB-C USB-A ECU AFR
      Atmospheric IOE F-Head Flathead Knucklehead Panhead Shovelhead Ironhead
      Evolution Sportster Revolution Milwaukee-Eight Twin V-Twin Flat Single
      Two-Stroke OHV Two-Cam Dyna Softail Springer Hydra-Glide
      X-Ring O-Ring Spin-on Inline Radial Rotary Piggyback Slick
      Track Sport Touring Racing Enduro Supermoto Adventure Naked
    ].freeze

    # Satuan internasional yang sudah sama di semua bahasa.
    NEUTRAL = %r{\A(cc|hp|Nm|mm|cm|km|kg|g|ml|l|L|dB|kV|kW|W|V|T|Hz|bar|oz|kgf|psi|C|A|D|S|M|XL|XXL|2XL|3XL|AA|PD|N95|IP\d+|[A-Z]{1,4}\d*|\d+[A-Z]*|[\d.,/:%+-]+)\z}

    module_function

    # "1.362" -> "1,362" (en/zh/ja) atau "1362" (ru); "0,8" -> "0.8".
    def localize_number(token, lang)
      if token.match?(/\A\d{1,3}(?:\.\d{3})+\z/)      # pemisah ribuan
        digits = token.delete(".")
        lang == "ru" ? digits : digits.reverse.scan(/\d{1,3}/).join(",").reverse
      elsif token.match?(/\A\d+,\d+\z/)               # pemisah desimal
        lang == "ru" ? token : token.tr(",", ".")
      else
        token
      end
    end

    # Kembalikan nil bila nilainya bukan sekadar angka dan satuan, sehingga
    # pemanggil bisa jatuh kembali ke kamus istilah.
    def localize(text, lang)
      return nil if text.nil? || lang.nil?

      words = text.to_s.split(/(\s+)/)
      out = words.map do |word|
        next word if word.strip.empty?

        bare = word.gsub(/[(),.]+\z/, "")
        suffix = word[bare.length..] || ""

        if bare.match?(%r{\A[\d.,/:+-]+\z})
          localize_number(bare, lang) + suffix
        elsif UNITS.key?(bare.downcase)
          UNITS[bare.downcase][lang] + suffix
        elsif PROPER_NOUNS.include?(bare) || bare.match?(NEUTRAL)
          word
        else
          return nil # ada kata yang bukan satuan: serahkan ke kamus
        end
      end

      joined = out.join
      # Bahasa yang tidak memakai spasi antara angka dan satuan.
      joined = joined.gsub(/(\d)\s+(个月|小时|分钟|天|年|秒|微米|节|档|轴|英寸|件|套|升)/, '\1 \2') if lang == "zh"
      joined
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

      # Nilai spesifikasi berpola angka dan satuan ditangani secara otomatis,
      # sehingga produk baru tidak perlu ditambahkan ke kamus.
      if kind.to_s == "spec_value"
        measured = HTZL::Measures.localize(text, lang.to_s)
        return measured if measured
      end

      entry = site_data.dig("i18n", "terms", kind.to_s, text.to_s) ||
              site_data.dig("i18n", "spec_values", kind.to_s, text.to_s)
      entry.is_a?(Hash) && entry[lang.to_s] ? entry[lang.to_s] : text
    end

    # Tulis tanggal mengikuti kebiasaan bahasanya.
    #   29 Mei 2022 | 29 May 2022 | 2022年5月29日 | 29 мая 2022
    def localize_date(value, lang)
      date = to_date(value)
      return "" if date.nil?

      dict = site_data.dig("i18n", lang.to_s, "date")
      return date.strftime("%-d %B %Y") if dict.nil? || dict["months"].nil?

      dict["pattern"].to_s
                     .gsub("%{d}", date.day.to_s)
                     .gsub("%{m}", dict["months"][date.month - 1].to_s)
                     .gsub("%{y}", date.year.to_s)
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

    def to_date(value)
      case value
      when Date, Time, DateTime then value
      when String then begin
        Date.parse(value)
      rescue StandardError
        nil
      end
      else value.respond_to?(:to_date) ? value.to_date : nil
      end
    end

    def site_object
      @context.registers[:site]
    end

    def site_data
      site_object.data
    end
  end

  # Filter gambar responsif untuk template di luar katalog: hero, banner, dan
  # foto pendukung. Item katalog sudah membawa daftar ukurannya sendiri di
  # _data/catalog.yml, jadi template katalog tidak memakai filter ini.
  module ImageFilters
    # Daftar srcset lengkap dengan baseurl, siap dipasang di atribut.
    #   <img srcset="{{ '/assets/img/hero/promo.webp' | srcset }}" ...>
    def srcset(web_path)
      variants = HTZL::ImageSources.variants(web_path)
      return "" if variants.nil? || variants.size < 2

      variants.map { |path, width| "#{with_baseurl(path)} #{width}w" }.join(", ")
    end

    # Kandidat terkecil yang masuk akal untuk dipreload, dipakai bersama
    # imagesrcset supaya peramban tetap bebas memilih.
    def largest_variant(web_path)
      variants = HTZL::ImageSources.variants(web_path)
      return with_baseurl(web_path) if variants.nil?

      with_baseurl(variants.last[0])
    end

    def image_width(web_path)
      HTZL::ImageSources.dimensions(web_path)&.first
    end

    def image_height(web_path)
      HTZL::ImageSources.dimensions(web_path)&.last
    end

    private

    def with_baseurl(path)
      base = @context.registers[:site].config["baseurl"].to_s
      "#{base}#{path}"
    end
  end
end
