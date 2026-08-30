# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require "json"
require "date"

ROOT = File.expand_path("..", __dir__)

require_relative "../lib/htzl/catalog"

module TestSupport
  LOCALES = %w[id en zh ru ja].freeze

  def catalog
    @catalog ||= HTZL::Catalog.build
  end

  # news.yml memuat tanggal, yang ditolak safe-load bawaan Psych.
  def data_file(name)
    YAML.load_file(File.join(ROOT, "_data", name), permitted_classes: [Date])
  end

  def i18n(locale)
    @i18n ||= {}
    @i18n[locale] ||= YAML.load_file(File.join(ROOT, "_data", "i18n", "#{locale}.yml"))
  end

  def terms
    @terms ||= YAML.load_file(File.join(ROOT, "_data", "i18n", "terms.yml"))
  end

  def site_path(*parts)
    File.join(ROOT, "_site", *parts)
  end

  def site_built?
    File.directory?(File.join(ROOT, "_site"))
  end

  # Kumpulkan semua kunci bersarang jadi jalur bertitik, untuk membandingkan
  # struktur antarbahasa.
  def flatten_keys(hash, prefix = "")
    hash.flat_map do |key, value|
      path = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
      case value
      when Hash  then flatten_keys(value, path)
      when Array then value.each_with_index.flat_map { |v, i| v.is_a?(Hash) ? flatten_keys(v, "#{path}[#{i}]") : ["#{path}[#{i}]"] }
      else [path]
      end
    end
  end
end
