# frozen_string_literal: true

require_relative "image_sources"

module HTZL
  # Menghubungkan tiap item katalog dengan berkas gambarnya: ukuran nyata untuk
  # atribut width dan height, serta daftar varian untuk srcset. Pencarian
  # berkasnya sendiri ada di HTZL::ImageSources, yang juga dipakai template
  # hero dan banner di luar katalog.
  module CatalogImages
    def image_dimensions(rel)
      HTZL::ImageSources.dimensions(rel)
    end

    def image_sources(rel)
      HTZL::ImageSources.variants(rel)
    end
  end
end
