# frozen_string_literal: true

require_relative "image_size"

module HTZL
  # Menemukan ukuran-ukuran yang tersedia untuk sebuah gambar.
  #
  # Varian dibuat lib/make_thumbnails.py dengan pola "<nama>-<lebar>.webp".
  # Modul ini tidak pernah menebak: ia hanya melaporkan berkas yang benar-benar
  # ada di disk, sehingga srcset tidak mungkin menunjuk ke berkas hilang.
  #
  # Dipakai dua tempat. Katalog memakainya lewat HTZL::CatalogImages saat
  # membangun data produk; template hero dan banner memakainya lewat filter
  # Liquid, karena gambarnya tidak berasal dari katalog.
  module ImageSources
    # Kartu produk butuh ukuran kecil, hero dan banner butuh yang besar.
    # Daftar tunggal ini cukup untuk keduanya: yang tidak ada berkasnya
    # otomatis dilewati.
    WIDTHS = [384, 640, 960, 1280].freeze

    module_function

    def root
      @root ||= File.expand_path("../..", __dir__)
    end

    def disk_path(web_path)
      File.join(root, web_path.sub(%r{\A/}, ""))
    end

    def dimensions(web_path)
      return nil if web_path.nil?

      @dimensions ||= {}
      @dimensions[web_path] ||= HTZL::ImageSize.read(disk_path(web_path)) || [630, 390]
      @dimensions[web_path].dup
    end

    # Daftar [jalur, lebar] menaik, selalu diakhiri berkas penuh.
    def variants(web_path)
      return nil if web_path.nil? || !web_path.end_with?(".webp")

      @variants ||= {}
      @variants[web_path] ||= build(web_path)
      @variants[web_path].map { |path, width| [path.dup, width] }
    end

    def build(web_path)
      full_width = dimensions(web_path)[0]
      stem = web_path.sub(/\.webp\z/, "")
      smaller = WIDTHS.filter_map do |width|
        variant = "#{stem}-#{width}.webp"
        [variant, width] if width < full_width && File.exist?(disk_path(variant))
      end
      smaller << [web_path, full_width]
    end
  end
end
