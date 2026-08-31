# frozen_string_literal: true

require "rake/testtask"

desc "Bangun ulang katalog (_data/catalog.yml) dari lib/htzl/catalog.rb"
task :seed do
  ruby "lib/seed_catalog.rb"
end

Rake::TestTask.new("test:ruby") do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
  t.verbose = false
end

desc "Uji fungsi JavaScript dengan test runner bawaan Node"
task "test:js" do
  sh "node --test test/js/*.test.mjs"
end

desc "Jalankan seluruh test, Ruby dan JavaScript"
task test: ["test:ruby", "test:js"]

desc "Periksa gaya dan kualitas kode Ruby"
task :lint do
  sh "bundle exec rubocop"
end

desc "Build situs statis ke _site"
task build: :seed do
  sh "bundle exec jekyll build --trace"
end

desc "Jalankan server pengembangan di http://localhost:4000"
task serve: :seed do
  sh "bundle exec jekyll serve --livereload --trace"
end

desc "Seed, build, test, lalu lint (dipakai CI)"
task ci: %i[seed build test lint]

namespace :i18n do
  desc "Laporan cakupan terjemahan"
  task :report do
    require "yaml"
    require_relative "lib/htzl/filters"
    require_relative "lib/htzl/catalog"

    locales = %w[en zh ru ja]
    terms = YAML.load_file("_data/i18n/terms.yml")
    values = YAML.load_file("_data/i18n/spec_values.yml")["spec_value"]
    items = HTZL::Catalog.build

    puts "Cakupan terjemahan katalog (#{items.length} item, #{locales.length} bahasa)"
    puts "-" * 64

    {
      "category"    => items.map { |i| i["category_label"] }.uniq,
      "subcategory" => items.map { |i| i["subcategory"] }.uniq,
      "spec_key"    => items.flat_map { |i| i["specs"].keys }.uniq
    }.each do |kind, used|
      covered = used.count { |term| terms.dig(kind, term) }
      puts format("  %-14s %3d/%-3d  %3d%%  lewat kamus", kind, covered, used.length,
                  used.empty? ? 100 : covered * 100 / used.length)
    end

    used = items.flat_map { |i| i["specs"].values }.uniq
    auto = used.count { |v| HTZL::Measures.localize(v, "en") }
    dict = used.count { |v| values.key?(v) }
    puts format("  %-14s %3d/%-3d  %3d%%  (%d otomatis, %d lewat kamus)",
                "spec_value", auto + dict, used.length,
                (auto + dict) * 100 / used.length, auto, dict)

    missing = used.reject { |v| HTZL::Measures.localize(v, "en") || values.key?(v) }
    puts
    if missing.empty?
      puts "Seluruh nilai spesifikasi tercakup."
    else
      puts "Belum diterjemahkan: #{missing.length} frasa x #{locales.length} bahasa"
      missing.first(10).each { |v| puts "    - #{v}" }
    end
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

namespace :build do
  desc "Bangun situs dengan baseurl kosong ke _preview, untuk uji end-to-end"
  task :preview do
    # Hasil build biasa memakai baseurl GitHub Pages, sehingga seluruh aset
    # menunjuk /htzl-motorcycle-club/... dan tidak bisa dilayani dari akar.
    # Uji end-to-end memerlukan salinan yang bisa dibuka apa adanya.
    sh "bundle exec jekyll build --baseurl \"\" -d _preview"
  end
end

desc "Uji end-to-end di peramban sungguhan (butuh Google Chrome)"
task e2e: "build:preview" do
  sh "node --test test/e2e/*.e2e.mjs"
end

desc "Laporan cakupan pengujian untuk kode Ruby di lib/"
task :coverage do
  ruby "-Itest lib/coverage_report.rb"
end

namespace :photos do
  desc "Ambil ulang foto heritage pada resolusi lebih tinggi (butuh Python + Pillow)"
  task :hires do
    sh "python lib/refetch_heritage_photos.py"
  end

  desc "Buat varian ukuran untuk srcset kartu, hero, dan banner (butuh Python + Pillow)"
  task :thumbs do
    sh "python lib/make_thumbnails.py"
    Rake::Task["seed"].invoke
  end
end
