# frozen_string_literal: true

require_relative "image_size"

module HTZL
  # Menghubungkan tiap item katalog dengan berkas gambarnya: ukuran nyata untuk
  # atribut width dan height, serta daftar varian untuk srcset. Dipisahkan dari
  # Catalog karena urusannya berkas di disk, bukan data produk.
  module CatalogImages
    # Daftar ukuran yang tersedia untuk satu gambar, dipakai sebagai srcset.
    # Kartu katalog hanya menampilkan gambar selebar 244 sampai 424 piksel,
    # jadi tanpa ini setiap kartu mengunduh berkas penuh yang jauh lebih besar
    # daripada yang dibutuhkan. Varian dibuat lib/make_thumbnails.py.
    THUMB_WIDTHS = [384, 640].freeze

    # Ukuran gambar dibaca dari berkasnya sendiri. Foto heritage tidak seragam
    # karena sebagian berkas asli di Commons lebih kecil dari lebar yang
    # diminta, jadi satu angka tetap untuk semuanya akan salah.
    def image_dimensions(rel)
      return nil if rel.nil?

      @image_dimensions ||= {}
      @image_dimensions[rel] ||=
        HTZL::ImageSize.read(File.expand_path("../..#{rel}", __dir__)) || [630, 390]
      # Salinan, bukan objek yang sama. Psych menulis objek berulang sebagai
      # anchor YAML, dan pembaca yang menolak alias akan gagal memuatnya.
      @image_dimensions[rel].dup
    end

    def image_sources(rel)
      return nil if rel.nil? || rel.end_with?(".svg")

      @image_sources ||= {}
      @image_sources[rel] ||= build_sources(rel)
      @image_sources[rel].map { |path, width| [path.dup, width] }
    end

    def build_sources(rel)
      full = image_dimensions(rel)
      stem = rel.sub(/\.webp\z/, "")
      sources = THUMB_WIDTHS.filter_map do |width|
        variant = "#{stem}-#{width}.webp"
        [variant, width] if width < full[0] && File.exist?(File.expand_path("../..#{variant}", __dir__))
      end
      sources << [rel, full[0]]
    end
  end
end
