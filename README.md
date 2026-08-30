<div align="center">

<img src="assets/img/logo.webp" width="120" alt="HTZL Motorcycle Club">

# HTZL Motorcycle Club

**Situs dealer sepeda motor statis — dibangun dengan Ruby, tersedia dalam lima bahasa.**

Katalog 131 item dengan harga transparan, pencarian instan, dan formulir reservasi
yang benar-benar mengirim pesanan. Tanpa framework, tanpa basis data, tanpa server.

[![Deploy](https://github.com/xyb3rpunq/htzl-motorcycle-club/actions/workflows/deploy.yml/badge.svg)](https://github.com/xyb3rpunq/htzl-motorcycle-club/actions/workflows/deploy.yml)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![Jekyll](https://img.shields.io/badge/Jekyll-4.3-CC0000?logo=jekyll&logoColor=white)](https://jekyllrb.com)
[![Tests](https://img.shields.io/badge/Minitest-88%20lolos-3fb950)](test)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

### [→ Buka situsnya](https://xyb3rpunq.github.io/htzl-motorcycle-club/)

**[🇮🇩 Indonesia](https://xyb3rpunq.github.io/htzl-motorcycle-club/)** ·
[🇬🇧 English](https://xyb3rpunq.github.io/htzl-motorcycle-club/en/) ·
[🇨🇳 简体中文](https://xyb3rpunq.github.io/htzl-motorcycle-club/zh/) ·
[🇷🇺 Русский](https://xyb3rpunq.github.io/htzl-motorcycle-club/ru/) ·
[🇯🇵 日本語](https://xyb3rpunq.github.io/htzl-motorcycle-club/ja/)

</div>

---

## Daftar isi

- [Dari tugas kuliah 2021 ke produk 2026](#dari-tugas-kuliah-2021-ke-produk-2026)
- [Fitur](#fitur)
- [Arsitektur](#arsitektur)
- [Katalog: 131 item dari 300 baris Ruby](#katalog-131-item-dari-300-baris-ruby)
- [Lima bahasa, lima URL](#lima-bahasa-lima-url)
- [Performa](#performa)
- [Aksesibilitas](#aksesibilitas)
- [Menjalankan di komputer sendiri](#menjalankan-di-komputer-sendiri)
- [Perintah rake](#perintah-rake)
- [Pengujian](#pengujian)
- [Penerbitan](#penerbitan)
- [Struktur proyek](#struktur-proyek)
- [Lisensi](#lisensi)

---

## Dari tugas kuliah 2021 ke produk 2026

Proyek ini berawal dari tugas mata kuliah pemrograman web tahun 2021: lima berkas
HTML statis, jQuery untuk satu slider, dan gambar mentah yang belum dikompres sama
sekali. Versi 2026 menulis ulang seluruhnya di atas Ruby dan Jekyll.

| | Versi 2021 | Versi 2026 |
|---|---|---|
| **Halaman** | 5 berkas HTML ditulis tangan | 31 halaman dibuat generator Ruby |
| **Bahasa** | 1 (Indonesia) | 5 (ID, EN, ZH, RU, JA) dengan `hreflang` |
| **Produk** | 12 motor, ditulis manual di HTML | 131 item dari sumber tunggal Ruby |
| **Ukuran aset** | 19,6 MB | **3,2 MB** (turun 85%) |
| **Payload katalog** | — | **30 KB** setelah gzip |
| **JavaScript** | jQuery 89 KB, blocking di `<head>` | 14 KB vanilla, `defer` |
| **Saat layar diputar** | `location.reload()` — halaman muat ulang penuh | tidak terjadi apa-apa |
| **Menu di layar sentuh** | mati (hanya `:hover`) | drawer + dropdown yang bisa diklik |
| **Formulir pesanan** | `alert()`, data hilang | ringkasan harga + kirim ke WhatsApp |
| **Gambar** | tanpa `alt`, `width`, `height`, `lazy` | lengkap semua, nol pergeseran tata letak |
| **Tema gelap** | tidak ada | ada, mengikuti sistem, bisa diganti |
| **SEO** | tanpa `description`, OG, sitemap | lengkap + JSON-LD `AutoDealer` |
| **Pengujian** | tidak ada | 88 test, 10.842 assertion |

<details>
<summary><b>Tampilan versi 2021 (klik untuk lihat)</b></summary>

<br>

| Katalog produk | Galeri | Reservasi |
|---|---|---|
| <img src="docs/before-product.webp" alt="Halaman produk versi 2021"> | <img src="docs/before-gallery.webp" alt="Halaman galeri versi 2021"> | <img src="docs/before-reserve.webp" alt="Halaman reservasi versi 2021"> |

</details>

---

## Fitur

**Katalog**
- 131 item dalam 6 kategori: motor, apparel, sparepart, oli, aksesori, layanan
- Pencarian multi-kata seketika, tanpa permintaan jaringan
- Saringan kategori, merek, dan rentang harga yang bisa digabung
- Urutkan berdasarkan harga, nama, atau rating
- Tampilan kisi dan daftar
- Keadaan saringan tersimpan di URL, jadi tautannya bisa dibagikan
- Dialog detail dengan tabel spesifikasi lengkap dan tombol pesan

**Antarmuka**
- Tata letak cair dari 320 px sampai monitor ultrawide
- Tema terang dan gelap, mengikuti sistem dan bisa diganti manual
- Slider hero berbasis `scroll-snap`: geser dengan jari didukung browser secara asli
- Lightbox galeri memakai elemen `<dialog>` bawaan browser
- Formulir reservasi dengan validasi sebaris, ringkasan harga langsung, dan kirim ke WhatsApp

**Fondasi**
- Nol dependensi runtime. Tidak ada jQuery, tidak ada framework CSS
- Font di-host sendiri: tidak ada satu pun permintaan ke server pihak ketiga
- Ikon berupa sprite SVG sebaris — 95 item non-motor tidak butuh satu berkas gambar pun
- `sitemap.xml`, `robots.txt`, manifes PWA, dan halaman 404 dibuat otomatis
- Katalog juga diterbitkan sebagai JSON statis di [`/assets/catalog.json`](https://xyb3rpunq.github.io/htzl-motorcycle-club/assets/catalog.json)

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
| `app/models/` | `lib/htzl/catalog.rb` | Sumber tunggal data produk |
| `app/helpers/` | `lib/htzl/filters.rb` | Pemformat rupiah, slug, tautan WhatsApp |
| `config/locales/` | `_data/i18n/*.yml` | String antarmuka lima bahasa |
| `app/views/layouts/` | `_layouts/` | Kerangka halaman |
| `app/views/shared/` | `_includes/` | Komponen yang dipakai berulang |
| `config/routes.rb` | `lib/htzl/locales.rb` | Cetak biru URL per bahasa |
| `Rakefile` + Minitest | `Rakefile` + `test/` | Perintah dan pengujian |

Aturan yang dipegang: **seluruh logika ada di `lib/`, dan `_plugins/` hanya
adapter tipis ke Jekyll.** Dengan begitu setiap fungsi bisa diuji Minitest tanpa
menjalankan Jekyll sama sekali.

```
lib/htzl/catalog.rb  ──rake seed──>  _data/catalog.yml  ──jekyll build──>  _site/
   (Ruby murni)                       (131 item)                          (31 halaman)
```

---

## Katalog: 131 item dari 300 baris Ruby

Produk tidak ditulis satu per satu di HTML. Semuanya dibangun program dari
`lib/htzl/catalog.rb` dengan seed acak tetap (`20161230`, tanggal berdiri HTZL),
jadi hasilnya selalu sama di setiap build — CI bahkan memverifikasi ini lewat
`git diff --exit-code`.

| Kategori | Jumlah | Rentang harga |
|---|--:|---|
| Motor (12 model × 3 trim) | 36 | Rp 40 jt – 98,5 jt |
| Sparepart & performa | 30 | Rp 145 rb – 14,2 jt |
| Apparel & gear | 26 | Rp 165 rb – 11,5 jt |
| Aksesori & touring | 15 | Rp 295 rb – 7,8 jt |
| Oli & perawatan | 14 | Rp 75 rb – 1,05 jt |
| Layanan bengkel | 10 | Rp 185 rb – 2,45 jt |
| **Total** | **131** | **Rp 75.000 – Rp 98.500.000** |

Setiap item punya SKU unik, slug, kategori, merek, harga, harga coret, stok,
rating, lencana, dan 4–6 baris spesifikasi.

Menambah produk cukup dengan menyunting satu larik di `lib/htzl/catalog.rb`
lalu menjalankan `rake seed` — kartu, saringan, penghitung kategori, sitemap,
dan JSON API ikut menyesuaikan sendiri.

---

## Lima bahasa, lima URL

Setiap bahasa punya alamatnya sendiri, bukan diganti lewat JavaScript. Ini
penting agar mesin pencari mengindeks tiap bahasa sebagai halaman terpisah.

| Bahasa | Kode | Alamat |
|---|---|---|
| Bahasa Indonesia | `id` | `/` |
| English | `en` | `/en/` |
| 简体中文 | `zh-Hans` | `/zh/` |
| Русский | `ru` | `/ru/` |
| 日本語 | `ja` | `/ja/` |

Satu generator Ruby (`_plugins/i18n.rb`) mengalikan 6 cetak biru halaman dengan
5 bahasa menjadi 30 halaman, lengkap dengan `hreflang` timbal balik dan
`x-default`.

**Cakupan terjemahan.** Seluruh antarmuka, naskah halaman, nama kategori
(6), subkategori (28), dan nama spesifikasi (105) diterjemahkan penuh ke lima
bahasa. *Nilai* spesifikasi sebagian besar netral bahasa karena berupa angka dan
satuan (`1.362 cc`, `CE Level 2`, `120/70 ZR17`); sisanya masih memakai istilah
Indonesia dan jatuh kembali secara otomatis lewat kamus di
`_data/i18n/terms.yml`. Jalankan `rake i18n:report` untuk melihat angka
cakupannya kapan saja.

---

## Performa

Diukur pada halaman katalog — halaman terberat, berisi 131 kartu produk sekaligus.

| Metrik | Nilai |
|---|---|
| HTML katalog setelah gzip | **30 KB** (419 KB mentah) |
| HTML beranda setelah gzip | **8,5 KB** |
| DOMContentLoaded | **175 ms** |
| Muat penuh | **191 ms** |
| Total simpul DOM | 3.386 |
| Permintaan JavaScript | 2 berkas, 14 KB, keduanya `defer` |
| Permintaan pihak ketiga | **0** |

Yang membuatnya ringan:

- Seluruh 131 kartu dirender saat build, jadi tetap terbaca tanpa JavaScript dan terindeks mesin pencari
- Penyaringan hanya menyembunyikan elemen di DOM — nol permintaan jaringan, nol jeda
- `content-visibility: auto` membuat browser melewati kartu yang belum terlihat
- Semua gambar WebP, punya `width`/`height`, dan `loading="lazy"` kecuali gambar pertama
- 95 item non-motor memakai ikon dari sprite SVG, bukan berkas gambar

---

## Aksesibilitas

- Navigasi keyboard penuh, dengan indikator fokus yang jelas di semua kontrol
- Tautan lewati-ke-konten
- Dialog memakai elemen `<dialog>` bawaan, sehingga jebakan fokus dan tombol Esc ditangani browser
- Semua gambar punya `alt` yang bermakna
- Target sentuh minimal 44 px
- `aria-current`, `aria-expanded`, `aria-pressed`, dan `role="alert"` pada galat formulir
- Menghormati `prefers-reduced-motion`: putar otomatis dan animasi dimatikan
- Kontras warna terjaga di tema terang maupun gelap

---

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
bundle exec rake build        # seed lalu build ke _site
bundle exec rake serve        # server pengembangan dengan livereload
bundle exec rake test         # jalankan seluruh test
bundle exec rake ci           # seed, build, lalu test (dipakai GitHub Actions)
bundle exec rake i18n:report  # laporan cakupan terjemahan
```

---

## Pengujian

88 test, 10.842 assertion, berjalan dalam 0,6 detik.

| Berkas | Test | Cakupan |
|---|--:|---|
| `test/catalog_test.rb` | 24 | Tiap fungsi publik `HTZL::Catalog`, keunikan SKU dan slug, kewajaran harga, konsistensi trim, keberadaan berkas gambar |
| `test/filters_test.rb` | 19 | Tiap filter Liquid, termasuk penyandian URL untuk huruf Kiril dan penanganan nilai `nil` |
| `test/i18n_test.rb` | 15 | Struktur kunci identik di lima bahasa, tidak ada nilai kosong, kamus menutupi seluruh data katalog |
| `test/build_test.rb` | 20 | Hasil build: tautan aset tidak putus, `hreflang` lengkap, tidak ada sisa sintaks Liquid, anggaran ukuran halaman |
| `test/css_test.rb` | 10 | Penjaga regresi untuk bug tata letak yang pernah terjadi |

Dua test di `css_test.rb` menjaga bug nyata yang ditemukan saat pengujian di
peramban dan sudah diperbaiki:

1. **`backdrop-filter` pada `.site-header`.** Properti ini membuat containing
   block baru untuk keturunan `position: fixed`, sehingga drawer mobile ikut
   terpotong setinggi header — menunya jadi kotak 60 px berisi padding saja.
   Efek blur dipindahkan ke pseudo-element.
2. **Panel dropdown bahasa meluber ke luar viewport** di layar 1366 px dan
   membuat halaman bisa digeser mendatar. Sekarang panel di dekat tepi kanan
   dibuka ke arah dalam.

---

## Penerbitan

Setiap dorongan ke `main` memicu [GitHub Actions](.github/workflows/deploy.yml):

1. Pasang Ruby 3.3 dan gem yang dibutuhkan
2. `rake seed`, lalu pastikan katalog hasil seed tidak berubah (`git diff --exit-code`)
3. `jekyll build`
4. Jalankan seluruh test — **penerbitan dibatalkan bila ada yang gagal**
5. Terbitkan `_site` ke GitHub Pages

Pull request hanya diuji, tidak diterbitkan.

---

## Struktur proyek

```
htzl-motorcycle-club/
├── lib/htzl/
│   ├── catalog.rb          # sumber tunggal 131 produk
│   ├── filters.rb          # helper pemformatan dan penerjemah
│   └── locales.rb          # daftar bahasa dan cetak biru URL
├── lib/seed_catalog.rb     # padanan db/seeds.rb
├── _plugins/
│   ├── i18n.rb             # generator 30 halaman berbahasa
│   ├── htzl_filters.rb     # pendaftaran filter ke Liquid
│   └── catalog_api.rb      # penerbit /assets/catalog.json
├── _data/
│   ├── catalog.yml         # dibuat otomatis, jangan disunting
│   ├── news.yml
│   └── i18n/               # id, en, zh, ru, ja, terms
├── _layouts/               # home, catalog, brand, gallery, reserve, 404
├── _includes/              # head, header, footer, kartu produk, sprite ikon
├── assets/
│   ├── css/site.css        # 1.193 baris, tanpa framework
│   ├── js/                 # site, catalog, reserve — 769 baris vanilla
│   ├── fonts/              # Arvo, di-host sendiri
│   └── img/                # WebP, 3,2 MB total
├── test/                   # 88 test Minitest
└── .github/workflows/      # CI dan penerbitan
```

---

## Lisensi

Kode berlisensi [MIT](LICENSE). Font Arvo berlisensi SIL Open Font License 1.1.
Gambar berasal dari sumber pihak ketiga dan hak ciptanya tetap milik pemegang
aslinya — rinciannya ada di [NOTICE.md](NOTICE.md).

> **HTZL Motorcycle Club adalah perusahaan fiktif.** Situs ini karya portofolio
> untuk keperluan belajar. Tidak ada afiliasi dengan produsen sepeda motor mana
> pun. Seluruh harga, spesifikasi, stok, dan berita adalah data contoh yang
> dibuat oleh program.

<div align="center">
<br>
Dibuat oleh <a href="https://github.com/xyb3rpunq">Daniel Hutajulu</a>
</div>
