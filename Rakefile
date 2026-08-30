# frozen_string_literal: true

require "rake/testtask"

desc "Bangun ulang katalog (_data/catalog.yml) dari lib/htzl/catalog.rb"
task :seed do
  ruby "lib/seed_catalog.rb"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
  t.verbose = false
end

desc "Build situs statis ke _site"
task build: :seed do
  sh "bundle exec jekyll build --trace"
end

desc "Jalankan server pengembangan di http://localhost:4000"
task serve: :seed do
  sh "bundle exec jekyll serve --livereload --trace"
end

desc "Seed, build, lalu jalankan seluruh test (dipakai CI)"
task ci: %i[seed build test]

namespace :i18n do
  desc "Laporan cakupan terjemahan per bahasa"
  task :report do
    require "yaml"
    require_relative "lib/htzl/catalog"

    locales = %w[en zh ru ja]
    terms = YAML.load_file("_data/i18n/terms.yml")
    items = HTZL::Catalog.build

    puts "Cakupan kamus istilah"
    puts "-" * 62
    {
      "category"    => items.map { |i| i["category_label"] }.uniq,
      "subcategory" => items.map { |i| i["subcategory"] }.uniq,
      "spec_key"    => items.flat_map { |i| i["specs"].keys }.uniq
    }.each do |kind, used|
      covered = used.count { |term| terms.dig(kind, term) }
      pct = used.empty? ? 100 : covered * 100 / used.length
      puts format("  %-14s %3d/%-3d  %3d%%", kind, covered, used.length, pct)
    end

    values = items.flat_map { |i| i["specs"].values }.uniq
    numeric = values.count { |v| v.match?(/\A[\d\s.,\-\/]+\s*[a-zA-Z%]*\z/) }
    covered = values.count { |v| terms.dig("spec_value", v) }
    puts format("  %-14s %3d/%-3d  %3d%%  (%d nilai berupa angka/satuan, netral bahasa)",
                "spec_value", covered + numeric, values.length,
                (covered + numeric) * 100 / values.length, numeric)
    puts
    puts "Nilai spesifikasi yang masih memakai teks Indonesia:"
    todo = values.reject { |v| v.match?(/\A[\d\s.,\-\/]+\s*[a-zA-Z%]*\z/) || terms.dig("spec_value", v) }
    puts "  #{todo.length} frasa x #{locales.length} bahasa = #{todo.length * locales.length} string"
    todo.first(10).each { |v| puts "    - #{v}" }
    puts "    ..." if todo.length > 10
  end
end

task default: :ci

desc "Ambil foto Harley berlisensi bebas dari Wikimedia Commons (butuh Python + Pillow)"
task :photos do
  require "json"
  require_relative "lib/htzl/catalog"

  units = HTZL::Catalog.build
                       .select { |i| i["category"] == "heritage" }
                       .map { |i| { slug: i["slug"], year: i["year"], name: i["name"], query: i["photo_query"] } }

  ENV["HTZL_UNITS"] = JSON.generate(units)
  sh "python lib/fetch_heritage_photos.py"
end

desc "Buat artwork SVG untuk produk tanpa foto"
task :art do
  ruby "lib/generate_art.rb"
end
