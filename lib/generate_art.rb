# frozen_string_literal: true

# Membuat artwork produk untuk item yang tidak punya foto berlisensi bebas.
#
#   rake art
#
# Tiap berkas adalah SVG berukuran sekitar 2 KB: gradien khas kategori, ikon
# besar yang diambil ulang dari sprite di _includes/icons.html, lalu nama dan
# kode produk. Karena digambar program, hasilnya bersih secara lisensi,
# konsisten, dan jauh lebih ringan daripada foto.

require_relative "htzl/catalog"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
OUT_DIR = File.join(ROOT, "assets", "img", "products")
SPRITE = File.join(ROOT, "_includes", "icons.html")

WIDTH = 630
HEIGHT = 390

# Dua warna gradien per kategori.
PALETTE = {
  "apparel"  => ["#3b2f73", "#6d5cc0"],
  "part"     => ["#1e4560", "#3d82ad"],
  "oli"      => ["#7d4f0e", "#cf9333"],
  "aksesori" => ["#11554f", "#2b9c93"],
  "layanan"  => ["#18553a", "#31a273"],
  "heritage" => ["#3a2d26", "#8a6a4f"]
}.freeze

# Ambil isi tiap <symbol> dari sprite supaya ikon tidak perlu ditulis dua kali.
def load_icons
  markup = File.read(SPRITE, encoding: "utf-8")
  markup.scan(%r{<symbol id="i-([a-z0-9-]+)"(.*?)>(.*?)</symbol>}m).each_with_object({}) do |(id, attrs, inner), acc|
    acc[id] = {
      body:  inner.strip,
      fill:  attrs[/fill="([^"]+)"/, 1] || "none",
      width: attrs[/stroke-width="([^"]+)"/, 1] || "1.7"
    }
  end
end

# Pembeda antaritem yang tetap sama pada tiap build.
def digest(text)
  text.each_byte.reduce(7) { |acc, byte| ((acc * 31) + byte) % 100_000 }
end

def escape(text)
  text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

# Bagi nama menjadi paling banyak dua baris agar muat di kartu.
def wrap(name, limit = 30)
  words = name.split
  lines = [""]
  words.each do |word|
    if "#{lines.last} #{word}".strip.length <= limit || lines.last.empty?
      lines[-1] = "#{lines.last} #{word}".strip
    elsif lines.length < 2
      lines << word
    else
      lines[-1] = "#{lines.last} ..."
      break
    end
  end
  lines.reject(&:empty?)
end

# Bentuk latar: sudut gradien dan dua lingkaran, ditentukan dari SKU supaya
# tiap produk berbeda tetapi tetap sama pada tiap build.
def backdrop(item)
  seed = digest(item["sku"].to_s + item["name"].to_s)
  {
    angle:  (seed % 60) + 15,
    blob_x: 90 + (seed % 420),
    blob_y: 40 + (seed / 7 % 260),
    radius: 150 + (seed / 3 % 120)
  }
end

# Blok teks nama dan kode produk di sudut kiri bawah kartu.
def build_label(item)
  lines = wrap(item["name"])
  text_y = lines.length > 1 ? 300 : 316

  rows = lines.each_with_index.map do |line, i|
    %(<text x="40" y="#{text_y + (i * 30)}" font-size="25" font-weight="700">#{escape(line)}</text>)
  end
  rows << (%(<text x="40" y="#{text_y + (lines.length * 30) + 6}" font-size="15" font-weight="600" ) +
          %(opacity="0.72" letter-spacing="1.5">#{escape(item["sku"])}</text>))

  rows.join("
    ")
end

def build_svg(item, icons)
  icon = icons[item["icon"]] || icons["motorcycle"]
  from, to = PALETTE.fetch(item["category"], PALETTE["part"])
  bg = backdrop(item)

  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{WIDTH} #{HEIGHT}" width="#{WIDTH}" height="#{HEIGHT}" role="img" aria-label="#{escape(item["name"])}">
      <defs>
        <linearGradient id="bg" gradientTransform="rotate(#{bg[:angle]})">
          <stop offset="0%" stop-color="#{from}"/>
          <stop offset="100%" stop-color="#{to}"/>
        </linearGradient>
      </defs>
      <rect width="#{WIDTH}" height="#{HEIGHT}" fill="url(#bg)"/>
      <circle cx="#{bg[:blob_x]}" cy="#{bg[:blob_y]}" r="#{bg[:radius]}" fill="#ffffff" opacity="0.06"/>
      <circle cx="#{WIDTH - (bg[:blob_x] / 2)}" cy="#{HEIGHT - (bg[:blob_y] / 3)}" r="#{bg[:radius] / 2}" fill="#000000" opacity="0.08"/>
      <g transform="translate(#{(WIDTH - 132) / 2} 62) scale(5.5)" fill="#{icon[:fill]}" stroke="#ffffff" stroke-width="#{icon[:width]}" stroke-linecap="round" stroke-linejoin="round" opacity="0.95">
        #{icon[:body]}
      </g>
      <g font-family="system-ui, 'Segoe UI', Roboto, Arial, sans-serif" fill="#ffffff">
        #{build_label(item)}
      </g>
    </svg>
  SVG
end

icons = load_icons
FileUtils.mkdir_p(OUT_DIR)

items = HTZL::Catalog.build.reject { |i| i["category"] == "motor" }
written = 0
bytes = 0

items.each do |item|
  # Unit heritage yang sudah punya foto asli tidak perlu artwork.
  next if item["image"] && !item["image"].include?("/products/")

  path = File.join(OUT_DIR, "#{item["slug"]}.svg")
  File.binwrite(path, build_svg(item, icons))
  written += 1
  bytes += File.size(path)
end

puts "Artwork dibuat: #{written} berkas, total #{bytes / 1024} KB"
puts "Rata-rata #{bytes / [written, 1].max} byte per berkas"
puts "Ikon terbaca dari sprite: #{icons.keys.length}"
