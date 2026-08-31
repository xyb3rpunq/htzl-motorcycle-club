<div align="center">

<img src="assets/img/logo.webp" width="110" alt="HTZL Motorcycle Club">

# HTZL Motorcycle Club

**Situs dealer sepeda motor statis — dibangun dengan Ruby, tersedia dalam lima bahasa.**

Katalog 231 item dengan harga transparan, pencarian instan, koleksi Harley-Davidson
1903–2017, dan formulir reservasi yang benar-benar mengirim pesanan.
Tanpa framework, tanpa basis data, tanpa server.

[![Deploy](https://github.com/xyb3rpunq/htzl-motorcycle-club/actions/workflows/deploy.yml/badge.svg)](https://github.com/xyb3rpunq/htzl-motorcycle-club/actions/workflows/deploy.yml)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![Jekyll](https://img.shields.io/badge/Jekyll-4.3-CC0000?logo=jekyll&logoColor=white)](https://jekyllrb.com)
[![Tests](https://img.shields.io/badge/tes-127%20Ruby%20%2B%2023%20JS-3fb950)](test)
[![A11y](https://img.shields.io/badge/axe--core-0%20pelanggaran-3fb950)](#aksesibilitas)
[![Bahasa](https://img.shields.io/badge/bahasa-ID%20EN%20ZH%20RU%20JA-4c7cf0)](#lima-bahasa-lima-url)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

### [→ Buka situsnya](https://xyb3rpunq.github.io/htzl-motorcycle-club/)

**[🇮🇩 Indonesia](https://xyb3rpunq.github.io/htzl-motorcycle-club/)** ·
[🇬🇧 English](https://xyb3rpunq.github.io/htzl-motorcycle-club/en/) ·
[🇨🇳 简体中文](https://xyb3rpunq.github.io/htzl-motorcycle-club/zh/) ·
[🇷🇺 Русский](https://xyb3rpunq.github.io/htzl-motorcycle-club/ru/) ·
[🇯🇵 日本語](https://xyb3rpunq.github.io/htzl-motorcycle-club/ja/)

<br>

<img src="docs/shots/beranda.webp" alt="Beranda HTZL Motorcycle Club">

</div>

---

## Daftar isi

- [Fitur](#fitur)
  - [Katalog 231 item](#katalog-231-item)
  - [Koleksi Heritage: 100 Harley-Davidson](#koleksi-heritage-100-harley-davidson)
  - [Garis waktu generasi mesin](#garis-waktu-generasi-mesin)
  - [Dialog detail produk](#dialog-detail-produk)
  - [Galeri dan reservasi](#galeri-dan-reservasi)
  - [Lima bahasa, lima URL](#lima-bahasa-lima-url)
  - [Tampilan ponsel](#tampilan-ponsel)
- [Dari tugas kuliah 2021 ke produk 2026](#dari-tugas-kuliah-2021-ke-produk-2026)
- [Arsitektur](#arsitektur)
- [Katalog dibangun dari Ruby](#katalog-dibangun-dari-ruby)
- [Terjemahan: dua lapis](#terjemahan-dua-lapis)
- [Foto dan lisensi](#foto-dan-lisensi)
- [Performa](#performa)
- [Aksesibilitas](#aksesibilitas)
- [Menjalankan di komputer sendiri](#menjalankan-di-komputer-sendiri)
- [Perintah rake](#perintah-rake)
- [Pengujian](#pengujian)
- [Penerbitan](#penerbitan)
- [Struktur proyek](#struktur-proyek)
- [Lisensi](#lisensi)

> Seluruh tangkapan layar di bawah diambil dari situs yang benar-benar berjalan
> memakai Chrome headless, bukan mockup.

---

## Fitur

### Katalog 231 item

Semua kartu dirender saat build, jadi katalog tetap terbaca tanpa JavaScript dan
terindeks mesin pencari. Penyaringan hanya menyembunyikan elemen di DOM: nol
permintaan jaringan, nol jeda.

<img src="docs/shots/katalog.webp" alt="Halaman katalog dengan bilah pencarian, saringan, dan kisi produk">

Pencarian menerima banyak kata sekaligus, dan seluruh keadaan saringan tersimpan
di URL sehingga tautannya bisa dibagikan. Tampilan bisa diubah menjadi daftar.

<img src="docs/shots/katalog-cari.webp" alt="Hasil pencarian kata kunci helm dalam tampilan daftar">

| Kontrol | Perilaku |
|---|---|
| Pencarian | Multi-kata, seketika, cocok pada nama, merek, jenis, dan kode |
| Kategori | Tujuh chip dengan penghitung isi masing-masing |
| Merek | Kawasaki, Vixian, Harley-Davidson, dan lini HTZL |
| Rentang harga | Enam tingkat, dari di bawah Rp 500 rb sampai di atas Rp 500 jt |
| Urutan | Relevansi, harga naik, harga turun, nama, rating |
| Tampilan | Kisi atau daftar |
| URL | `?q=helm&category=apparel&sort=price_asc&view=list` |

### Koleksi Heritage: 100 Harley-Davidson

Seratus unit diurutkan dari yang tertua: Model 1 Serial Number One 1903 sampai
Road King Milwaukee-Eight 2017. Model, tahun, dan generasi mesin mengikuti
sejarah produk yang sebenarnya, dikelompokkan ke sebelas generasi mesin dari Era
Perintis sampai Era Milwaukee-Eight.

<img src="docs/shots/katalog-heritage.webp" alt="Koleksi heritage Harley-Davidson dengan foto historis">

Enam puluh sembilan unit memakai **foto asli berlisensi bebas** dari Wikimedia
Commons, lengkap dengan atribusi. Sisanya memakai artwork SVG yang dibuat
program.

### Garis waktu generasi mesin

Koleksi ini punya halamannya sendiri di `/heritage/`, dengan garis waktu sebelas
generasi mesin. Urutan dan rentang tahunnya dihitung di Ruby saat build, bukan
ditulis manual, jadi ikut menyesuaikan sendiri kalau ada unit baru.

<img src="docs/shots/heritage.webp" alt="Halaman koleksi heritage dengan garis waktu generasi mesin">

Menekan satu generasi menyaring koleksinya seketika, dan pilihan itu masuk ke
URL sehingga bisa dibagikan:

| Generasi | Unit | Rentang tahun |
|---|--:|---|
| Era Perintis | 21 | 1903–1928 |
| Era Flathead | 18 | 1919–1964 |
| Era Evolution | 17 | 1984–1998 |
| Era Shovelhead | 13 | 1966–1983 |
| Era Panhead | 9 | 1948–1965 |
| Era Ironhead | 8 | 1957–1977 |
| Era Knucklehead | 4 | 1936–1946 |
| Era Model Ringan | 3 | 1927–1961 |
| Era Twin Cam | 3 | 1999–2011 |
| Era Revolution | 3 | 2001–2014 |
| Era Milwaukee-Eight | 1 | 2017 |

### Dialog detail produk

Bar bawah menempel sehingga tombol pesan selalu terjangkau, betapa pun panjang
tabel spesifikasinya.

<img src="docs/shots/dialog-heritage.webp" alt="Dialog detail produk untuk Harley-Davidson 1903">

- **Pengatur jumlah** dengan total harga yang berubah seketika
- **Panah kiri dan kanan** berpindah antarproduk tanpa menutup dialog, dengan penunjuk posisi `132 dari 231`
- **Salin tautan** menghasilkan alamat seperti `?item=HTZ-HER-132` yang langsung membuka produk itu bagi penerimanya
- **Pesan WhatsApp** memuat nama, kode, jumlah, total, dan tautan produk
- **Atribusi foto** ditampilkan di dalam dialog, sesuai syarat lisensi Creative Commons
- Tombol Esc menutup, fokus kembali ke tombol asalnya

<img src="docs/shots/dialog-motor.webp" alt="Dialog detail produk untuk Kawasaki x56 SP">

### Galeri dan reservasi

Galeri berisi 81 foto: dokumentasi showroom dan pameran, ditambah seluruh foto
koleksi heritage. Elemen `<dialog>` bawaan browser menangani jebakan fokus dan
tombol Esc; panah kiri dan kanan berpindah gambar, dan atribusi lisensi ikut
tampil untuk foto Creative Commons.

<img src="docs/shots/galeri.webp" alt="Halaman galeri">

Formulir reservasi memvalidasi secara sebaris, menghitung total pesanan langsung,
lalu menyusun pesan WhatsApp yang siap kirim. Tidak ada `alert()`, dan tidak ada
data yang hilang.

<img src="docs/shots/reservasi.webp" alt="Halaman reservasi dengan ringkasan pesanan">

### Lima bahasa, lima URL

Setiap bahasa punya alamatnya sendiri, bukan diganti lewat JavaScript. Ini
penting agar mesin pencari mengindeks tiap bahasa sebagai halaman terpisah.

| Bahasa | Kode | Alamat |
|---|---|---|
| Bahasa Indonesia | `id` | `/` |
| English | `en` | `/en/` |
| 简体中文 | `zh-Hans` | `/zh/` |
| Русский | `ru` | `/ru/` |
| 日本語 | `ja` | `/ja/` |

<img src="docs/shots/bahasa-ja.webp" alt="Katalog dalam bahasa Jepang">

<img src="docs/shots/bahasa-ru.webp" alt="Beranda dalam bahasa Rusia">

<img src="docs/shots/bahasa-zh.webp" alt="Katalog dalam bahasa Mandarin">

Satu generator Ruby mengalikan tujuh cetak biru halaman dengan lima bahasa
menjadi tiga puluh lima halaman, lengkap dengan `hreflang` timbal balik dan
`x-default`. Pindah bahasa **membawa serta filter yang sedang aktif**: dari
`/heritage/?sub=Era+Shovelhead&sort=price_desc` ke versi Jepangnya, hasil
saringannya tetap sama.

`sitemap.xml` ditulis sendiri, bukan memakai plugin, karena tiap `<url>` perlu
anotasi `xhtml:link` agar Google tahu kelima versi bahasa adalah halaman yang
sama. Hasilnya 35 URL dengan 210 anotasi bahasa.

Halaman 404 juga mengikuti bahasa. GitHub Pages hanya melayani satu berkas
`/404.html` untuk seluruh alamat, jadi kelima terjemahan disertakan di halaman
itu dan bahasanya dipilih dari awalan alamat yang gagal dibuka.

### Tampilan ponsel

Diuji pada lebar 390 piksel. Menu berupa drawer, dialog naik sebagai lembar dari
bawah dengan jarak aman untuk area gestur, dan halaman tidak pernah bisa digeser
mendatar.

<table>
<tr>
<td width="25%"><img src="docs/shots/hp-beranda.webp" alt="Beranda di ponsel"></td>
<td width="25%"><img src="docs/shots/hp-katalog.webp" alt="Katalog di ponsel"></td>
<td width="25%"><img src="docs/shots/hp-dialog.webp" alt="Dialog detail di ponsel"></td>
<td width="25%"><img src="docs/shots/hp-reservasi.webp" alt="Reservasi di ponsel"></td>
</tr>
</table>

---

## Dari tugas kuliah 2021 ke produk 2026

Proyek ini berawal dari tugas mata kuliah pemrograman web tahun 2021: lima berkas
HTML statis, jQuery untuk satu slider, dan gambar mentah yang belum dikompres
sama sekali. Versi 2026 menulis ulang seluruhnya di atas Ruby dan Jekyll.

| | Versi 2021 | Versi 2026 |
|---|---|---|
| **Halaman** | 5 berkas HTML ditulis tangan | 36 halaman dibuat generator Ruby |
| **Bahasa** | 1 (Indonesia) | 5 (ID, EN, ZH, RU, JA) dengan `hreflang` |
| **Produk** | 12 motor, ditulis manual di HTML | 231 item dari sumber tunggal Ruby |
| **Gambar produk** | 12 | 231, semuanya punya gambar |
| **Aset gambar** | 19,6 MB mentah | 6,7 MB, seluruhnya WebP dan SVG |
| **JavaScript** | jQuery 89 KB, blocking di `<head>` | 15 KB vanilla, `defer` |
| **Saat layar diputar** | `location.reload()` — muat ulang penuh | tidak terjadi apa-apa |
| **Menu di layar sentuh** | mati (hanya `:hover`) | drawer dan dropdown yang bisa diklik |
| **Formulir pesanan** | `alert()`, data hilang | ringkasan harga dan kirim ke WhatsApp |
| **Gambar** | tanpa `alt`, `width`, `height`, `lazy` | lengkap semua, nol pergeseran tata letak |
| **Tema gelap** | tidak ada | ada, mengikuti sistem, bisa diganti |
| **SEO** | tanpa `description`, OG, sitemap | lengkap dengan JSON-LD `AutoDealer` |
| **Lisensi aset** | tidak dicatat | 69 foto beratribusi, semuanya lisensi bebas |
| **Aksesibilitas** | tidak pernah diperiksa | 0 pelanggaran axe-core (WCAG 2.1 AA) |
| **Pengujian** | tidak ada | 127 test Ruby + 23 test JavaScript |

<details>
<summary><b>Tampilan versi 2021 (klik untuk lihat)</b></summary>

<br>

| Katalog produk | Galeri | Reservasi |
|---|---|---|
| <img src="docs/before-product.webp" alt="Halaman produk versi 2021"> | <img src="docs/before-gallery.webp" alt="Halaman galeri versi 2021"> | <img src="docs/before-reserve.webp" alt="Halaman reservasi versi 2021"> |

</details>

---

## Arsitektur

GitHub Pages hanya menyajikan berkas statis — Rails tidak bisa berjalan di sana
karena butuh proses server yang hidup. Jekyll adalah generator situs statis
berbasis Ruby yang didukung GitHub Pages secara asli, jadi proyek ini tetap
ditulis dalam Ruby sambil menghasilkan HTML yang termuat seketika.

Struktur proyeknya sengaja mengikuti konvensi Rails:

| Rails | Proyek ini | Isi |
|---|---|---|
| `db/seeds.rb` | `lib/seed_catalog.rb` | Menulis katalog ke `_data/` |
| `app/models/` | `lib/htzl/catalog.rb`, `lib/htzl/heritage.rb` | Sumber tunggal data produk |
| `app/helpers/` | `lib/htzl/filters.rb` | Rupiah, slug, tautan WhatsApp, pelokalan angka |
| `config/locales/` | `_data/i18n/*.yml` | String antarmuka dan kamus istilah |
| `app/views/layouts/` | `_layouts/` | Kerangka halaman |
| `app/views/shared/` | `_includes/` | Komponen yang dipakai berulang |
| `config/routes.rb` | `lib/htzl/locales.rb` | Cetak biru URL per bahasa |
| `lib/tasks/` | `Rakefile` | seed, art, photos, build, test |
| `test/` | `test/` | Minitest |

Aturan yang dipegang: **seluruh logika ada di `lib/`, dan `_plugins/` hanya
adapter tipis ke Jekyll.** Dengan begitu setiap fungsi bisa diuji Minitest tanpa
menjalankan Jekyll sama sekali.

```
lib/htzl/catalog.rb   ──rake seed──>  _data/catalog.yml   ──┐
lib/htzl/heritage.rb                  (231 item)            │
                                                            ├─jekyll build─> _site/
lib/generate_art.rb   ──rake art───>  assets/img/products/  │   (31 halaman)
lib/fetch_*.py        ──rake photos─> assets/img/heritage/  ─┘
```

---

## Katalog dibangun dari Ruby

Produk tidak ditulis satu per satu di HTML. Semuanya dibangun program dengan seed
acak tetap (`20161230`, tanggal berdiri HTZL), jadi hasilnya selalu sama di
setiap build — CI bahkan memverifikasi ini lewat `git diff --exit-code`.

| Kategori | Jumlah | Rentang harga |
|---|--:|---|
| Koleksi Heritage (Harley-Davidson 1903–2017) | 100 | Rp 150 jt – 4,5 M |
| Motor (12 model × 3 trim) | 36 | Rp 40 jt – 98,5 jt |
| Sparepart & performa | 30 | Rp 145 rb – 14,2 jt |
| Apparel & gear | 26 | Rp 165 rb – 11,5 jt |
| Aksesori & touring | 15 | Rp 295 rb – 7,8 jt |
| Oli & perawatan | 14 | Rp 75 rb – 1,05 jt |
| Layanan bengkel | 10 | Rp 185 rb – 2,45 jt |
| **Total** | **231** | **Rp 75.000 – Rp 4.500.000.000** |

Menambah produk cukup dengan menyunting satu larik di `lib/htzl/catalog.rb` lalu
menjalankan `rake seed` — kartu, saringan, penghitung kategori, sitemap, dan JSON
API ikut menyesuaikan sendiri.

---

## Terjemahan: dua lapis

Menerjemahkan katalog bukan sekadar soal kata. Bahasa Indonesia memakai titik
sebagai pemisah ribuan, sehingga `1.362 cc` terbaca **1,362** (satu koma tiga)
oleh pembaca berbahasa Inggris. Karena itu penanganannya dua lapis.

**Lapis 1 — algoritmik (`HTZL::Measures`).** Nilai berpola angka dan satuan
dilokalkan otomatis, sehingga produk baru tidak perlu entri kamus sama sekali.

| Sumber (ID) | EN / ZH / JA | RU |
|---|---|---|
| `1.362 cc` | `1,362 cc` | `1362 cc` |
| `0,8 mm` | `0.8 mm` | `0,8 mm` |
| `12 bulan` | `12 months` / `12 个月` | `12 мес.` |
| `120 mata` | `120 links` | `120 звеньев` |
| `ECE 22.06` | tidak diubah | tidak diubah |
| `Knucklehead` | tidak diubah | tidak diubah |

Kode standar dan nama diri sengaja dibiarkan apa adanya. Frasa yang memuat kata
Indonesia diserahkan ke lapis berikutnya, bukan diterjemahkan sebagian.

**Lapis 2 — kamus (`_data/i18n/*.yml`).** Seluruh istilah dan frasa yang tersisa
diterjemahkan penuh ke empat bahasa.

| Yang diterjemahkan | Jumlah | Cakupan |
|---|--:|---|
| Kategori | 7 | 100% |
| Subkategori | 39 | 100% |
| Nama spesifikasi | 108 | 100% |
| Nilai spesifikasi | 629 | 100% (340 otomatis, 289 kamus) |
| Antarmuka dan naskah halaman | seluruhnya | 100% |

```bash
bundle exec rake i18n:report
```

---

## Foto dan lisensi

Menempelkan watermark pada foto orang lain **tidak** menghapus hak cipta. Justru
berisiko dianggap mengklaim karya tersebut, dan menutupi informasi kepemilikan
merupakan pelanggaran tersendiri. Karena itu pendekatan yang dipakai berbeda:
hanya mengambil berkas yang lisensinya memang mengizinkan penggunaan ulang.

`rake photos` menanyai Wikimedia Commons dan **hanya menerima** domain publik,
CC0, CC BY, dan CC BY-SA. Berkas non-komersial atau tanpa turunan ditolak
otomatis.

| Lisensi | Jumlah foto |
|---|--:|
| CC BY-SA 4.0 | 48 |
| CC BY 2.0 | 7 |
| Domain publik | 5 |
| CC BY-SA 3.0 | 5 |
| CC BY-SA 2.0 | 3 |
| CC BY 4.0 | 1 |
| **Total** | **69** |

Nama pembuat, jenis lisensi, dan tautan sumber dicatat di
`_data/photo_credits.yml`, lalu ditampilkan di dua tempat: halaman detail tiap
produk, dan daftar lengkap di [NOTICE.md](NOTICE.md).

126 item sisanya memakai **artwork SVG yang dibuat program** oleh
`rake art`: gradien khas kategori, ikon besar yang diambil ulang dari sprite,
lalu nama dan kode produk. Rata-rata 1,1 KB per berkas, bersih secara lisensi.

---

## Performa

Diukur pada halaman katalog — halaman terberat, berisi 231 kartu produk sekaligus.

| Metrik | Nilai |
|---|---|
| HTML katalog setelah gzip | **47 KB** (720 KB mentah, 231 kartu) |
| HTML heritage setelah gzip | **24 KB** (100 kartu) |
| HTML beranda setelah gzip | **11 KB** |
| DOMContentLoaded | **175 ms** |
| Muat penuh | **191 ms** |
| Permintaan JavaScript | 2 berkas, 16 KB, keduanya `defer` |
| Permintaan pihak ketiga | **0** |

Yang membuatnya ringan:

- Seluruh kartu dirender saat build, jadi tetap terbaca tanpa JavaScript
- Penyaringan hanya menyembunyikan elemen di DOM — nol permintaan jaringan
- `content-visibility: auto` membuat browser melewati kartu yang belum terlihat
- Semua gambar WebP atau SVG, punya `width`/`height`, dan `loading="lazy"` kecuali yang pertama
- 126 item memakai artwork SVG rata-rata 1,1 KB
- Font Arvo di-host sendiri: nol permintaan ke Google Fonts

---

## Aksesibilitas

Diaudit dengan **axe-core** lewat Chrome DevTools Protocol pada aturan WCAG 2.1
A/AA ditambah best practice. Skripnya ada di riwayat commit; hasil terakhir:

| Halaman | Pelanggaran |
|---|--:|
| Beranda, katalog, heritage, galeri, reservasi, Kawasaki, Vixian, 404 | **0** |

Audit pertama menemukan 611 elemen bermasalah. Yang paling serius bukan soal
warna, melainkan **bug JavaScript**: selektor `[data-category]` dan `[data-view]`
ternyata juga cocok dengan 231 kartu produk dan elemen grid, sehingga
`aria-pressed` menempel ke ratusan elemen yang tidak boleh memilikinya. Selektor
kini dibatasi ke `<button>`.

Sisanya kontras warna di 322 elemen. Nilai penggantinya dihitung, bukan
dikira-kira:

| Token | Sebelum | Rasio | Sesudah | Rasio |
|---|---|--:|---|--:|
| `--ink-3` terang | `#8c837d` | 3,71 | `#786f69` | **4,91** |
| `--ink-3` gelap | `#857d77` | 4,42 | `#88807a` | **4,61** |
| Teks lencana gelap | `#fff` | 1,81 | `--ok-ink` | **9,08** |
| Hijau WhatsApp | `#1faa53` | 3,03 | `#148730` | **4,63** |
| Disclaimer footer | 45% | 4,48 | 62% | **6,7** |

`test/contrast_test.rb` membaca token langsung dari berkas gaya dan menghitung
rasionya sendiri, jadi palet yang terlalu pucat akan langsung menggagalkan test.

Selain itu:

- Navigasi keyboard penuh, dengan indikator fokus yang jelas di semua kontrol
- Tautan lewati-ke-konten, dan setiap halaman punya tepat satu `<h1>`
- Dialog memakai elemen `<dialog>` bawaan, sehingga jebakan fokus dan tombol Esc ditangani browser
- Target sentuh minimal 44 piksel
- `aria-current`, `aria-expanded`, `aria-pressed`, `aria-live`, dan `role="alert"` pada galat formulir
- Menghormati `prefers-reduced-motion`: putar otomatis dan animasi dimatikan

## Menjalankan di komputer sendiri

Prasyarat: Ruby 3.1 atau lebih baru.

```bash
git clone https://github.com/xyb3rpunq/htzl-motorcycle-club.git
cd htzl-motorcycle-club
bundle install
bundle exec rake serve
```

Situs akan tersedia di <http://localhost:4000/htzl-motorcycle-club/>.

---

## Perintah rake

```bash
bundle exec rake seed         # bangun ulang katalog dari lib/htzl/catalog.rb
bundle exec rake art          # buat artwork SVG untuk produk tanpa foto
bundle exec rake photos       # ambil foto berlisensi bebas dari Wikimedia Commons
bundle exec rake build        # seed lalu build ke _site
bundle exec rake serve        # server pengembangan dengan livereload
bundle exec rake test         # seluruh test, Ruby dan JavaScript
bundle exec rake test:ruby    # hanya Minitest
bundle exec rake test:js      # hanya test runner Node
bundle exec rake ci           # seed, build, lalu test (dipakai GitHub Actions)
bundle exec rake i18n:report  # laporan cakupan terjemahan
```

`rake photos` adalah tugas khusus pengembang dan membutuhkan Python dengan
Pillow. Hasilnya ikut disimpan di repositori, sehingga CI tidak pernah perlu
mengakses jaringan.

---

## Pengujian

**127 test Ruby** (22.161 assertion) dan **23 test JavaScript**, berjalan dalam kurang dari dua detik.

| Berkas | Cakupan |
|---|---|
| `test/catalog_test.rb` | Tiap fungsi publik `HTZL::Catalog`, keunikan SKU dan slug, kewajaran harga, konsistensi trim, keberadaan berkas gambar |
| `test/heritage_test.rb` | Koleksi berisi tepat 100 unit dengan nama unik dan urut dari yang tertua, tiap generasi mesin terpetakan, **setiap foto memakai lisensi bebas dan membawa atribusi lengkap** |
| `test/filters_test.rb` | Tiap filter Liquid, pelokalan angka per bahasa, penyandian URL huruf Kiril, penanganan nilai `nil` |
| `test/i18n_test.rb` | Struktur kunci identik di lima bahasa, tidak ada nilai kosong, kamus menutupi seluruh data katalog tanpa entri usang |
| `test/build_test.rb` | Hasil build: tautan aset tidak putus, `hreflang` lengkap, tidak ada sisa sintaks Liquid, anggaran ukuran halaman |
| `test/css_test.rb` | Penjaga regresi untuk bug tata letak yang pernah terjadi |
| `test/contrast_test.rb` | Menghitung rasio kontras tiap pasangan warna dari token yang sebenarnya, di kedua tema |
| `test/js/reserve.test.mjs` | Validator formulir dan penyusun tautan WhatsApp, dijalankan test runner bawaan Node |

Format rupiah punya **kontrak lintas bahasa**: Ruby memformatnya saat build,
JavaScript memformatnya lagi saat pengunjung mengubah jumlah pesanan. Keduanya
membaca daftar kasus yang sama di `test/fixtures/rupiah.json`, jadi keduanya
tidak bisa menyimpang diam-diam.

`css_test.rb` menjaga tiga bug nyata yang ditemukan saat pengujian di peramban
dan sudah diperbaiki:

1. **`backdrop-filter` pada `.site-header`.** Properti ini membuat containing
   block baru untuk keturunan `position: fixed`, sehingga drawer mobile ikut
   terpotong setinggi header — menunya jadi kotak 60 piksel berisi padding saja.
   Efek blur dipindahkan ke pseudo-element.
2. **Panel dropdown bahasa meluber ke luar viewport** di layar 1366 piksel dan
   membuat halaman bisa digeser mendatar. Dropdown di dekat tepi kanan sekarang
   dibuka ke arah dalam.
3. **Reset global `* { margin: 0 }` menimpa `margin: auto` bawaan `<dialog>`,**
   sehingga dialog detail produk menempel ke tepi kiri layar alih-alih berada di
   tengah.

---

## Penerbitan

Setiap dorongan ke `main` memicu [GitHub Actions](.github/workflows/deploy.yml):

1. Pasang Ruby 3.3 dan gem yang dibutuhkan
2. `rake seed`, lalu pastikan katalog hasil generator tidak berubah (`git diff --exit-code`)
3. `jekyll build`
4. Jalankan seluruh test — **penerbitan dibatalkan bila ada yang gagal**
5. Terbitkan `_site` ke GitHub Pages

Pull request hanya diuji, tidak diterbitkan.

---

## Struktur proyek

```
htzl-motorcycle-club/
├── lib/htzl/
│   ├── catalog.rb          # sumber tunggal 231 produk
│   ├── heritage.rb         # 100 Harley-Davidson, 1903 sampai 2017
│   ├── filters.rb          # helper pemformatan, penerjemah, pelokal angka
│   └── locales.rb          # daftar bahasa dan cetak biru URL
├── lib/seed_catalog.rb     # padanan db/seeds.rb
├── lib/generate_art.rb     # artwork SVG untuk produk tanpa foto
├── lib/fetch_heritage_photos.py  # pengambil foto berlisensi bebas
├── _plugins/
│   ├── i18n.rb             # generator 30 halaman berbahasa
│   ├── htzl_filters.rb     # pendaftaran filter ke Liquid
│   └── catalog_api.rb      # penerbit /assets/catalog.json
├── _data/
│   ├── catalog.yml         # dibuat otomatis, jangan disunting
│   ├── photo_credits.yml   # atribusi 69 foto Wikimedia
│   └── i18n/               # id, en, zh, ru, ja, terms, spec_values
├── _layouts/               # home, catalog, brand, heritage, gallery, reserve, 404
├── _includes/              # head, header, footer, kartu produk, dialog, sprite ikon
├── assets/
│   ├── css/site.css        # 1.373 baris, tanpa framework
│   ├── js/                 # site, catalog, reserve — 928 baris vanilla
│   ├── fonts/              # Arvo, di-host sendiri
│   └── img/                # WebP dan SVG
├── sitemap.xml             # ditulis sendiri, memuat anotasi hreflang
├── test/                   # 127 test Minitest + 23 test Node
└── .github/workflows/      # CI dan penerbitan
```

Total kode Ruby: 2.444 baris di 17 berkas.

---

## Lisensi

Kode berlisensi [MIT](LICENSE). Font Arvo berlisensi SIL Open Font License 1.1.
Foto koleksi heritage berlisensi domain publik atau Creative Commons dengan
atribusi. Rincian lengkapnya ada di [NOTICE.md](NOTICE.md).

> **HTZL Motorcycle Club adalah perusahaan fiktif.** Situs ini karya portofolio
> untuk keperluan belajar. Tidak ada afiliasi dengan produsen sepeda motor mana
> pun. Seluruh harga, spesifikasi, stok, dan berita adalah data contoh yang
> dibuat oleh program.

<div align="center">
<br>
Dibuat oleh <a href="https://github.com/xyb3rpunq">Daniel Hutajulu</a>
<br><br>
<a href="https://www.instagram.com/danielxyz_/">Instagram</a> ·
<a href="https://x.com/xyb3rpunk">X</a> ·
<a href="https://www.linkedin.com/in/daniel-hutajulu23/">LinkedIn</a>
</div>
