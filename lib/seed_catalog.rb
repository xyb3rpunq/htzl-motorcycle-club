# frozen_string_literal: true

# Padanan db/seeds.rb di Rails: membangun katalog lewat Ruby lalu menuliskannya
# ke _data/catalog.yml supaya Jekyll bisa merender semuanya jadi HTML statis.
#
#   ruby lib/seed_catalog.rb
#   rake seed

require_relative "htzl/catalog"
require "yaml"
require "json"
require "fileutils"

ROOT = File.expand_path("..", __dir__)

items = HTZL::Catalog.build
stats = HTZL::Catalog.stats(items)

FileUtils.mkdir_p(File.join(ROOT, "_data"))

File.write(
  File.join(ROOT, "_data", "catalog.yml"),
  "# DIBUAT OTOMATIS oleh lib/seed_catalog.rb - jangan diedit manual.\n" \
  "# Ubah sumbernya di lib/htzl/catalog.rb lalu jalankan: rake seed\n" +
  items.to_yaml
)

File.write(
  File.join(ROOT, "_data", "catalog_meta.yml"),
  "# DIBUAT OTOMATIS oleh lib/seed_catalog.rb\n" +
  {
    "total"      => stats["total"],
    "min_price"  => stats["min_price"],
    "max_price"  => stats["max_price"],
    "categories" => HTZL::Catalog::CATEGORIES.map do |key, meta|
      {
        "key"   => key,
        "label" => meta[:label],
        "icon"  => meta[:icon],
        "blurb" => meta[:blurb],
        "count" => stats["categories"][key].to_i
      }
    end,
    "brands"        => items.map { |i| i["brand"] }.uniq.sort,
    "subcategories" => items.map { |i| i["subcategory"] }.uniq.sort,
    # Generasi mesin koleksi heritage, diurutkan menurut tahun tertuanya.
    "eras"          => items.select { |i| i["category"] == "heritage" }
                            .group_by { |i| i["subcategory"] }
                            .map do |era, units|
                              years = units.map { |u| u["year"] }
                              {
                                "name"  => era,
                                "count" => units.length,
                                "from"  => years.min,
                                "to"    => years.max
                              }
                            end
                            .sort_by { |era| era["from"] }
  }.to_yaml
)

puts "Katalog dibuat: #{stats['total']} item"
stats["categories"].sort_by { |_, v| -v }.each do |key, count|
  puts format("  %-10s %3d item", key, count)
end
puts "  Harga  : #{HTZL::Catalog.rupiah(stats['min_price'])} - #{HTZL::Catalog.rupiah(stats['max_price'])}"
puts "  Ditulis: _data/catalog.yml, _data/catalog_meta.yml"
