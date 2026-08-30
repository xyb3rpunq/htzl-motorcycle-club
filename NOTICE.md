# Pemberitahuan Lisensi Pihak Ketiga

Repositori ini memakai beberapa aset yang tidak dilindungi lisensi MIT proyek.
Berkas ini merinci asal dan status lisensinya.

> Lisensi MIT di [LICENSE](LICENSE) berlaku untuk **kode** dalam repositori ini:
> seluruh berkas Ruby, CSS, JavaScript, templat Liquid, konfigurasi, dan test.
> Lisensi itu **tidak** berlaku untuk aset pihak ketiga (font dan gambar), yang
> dirinci di bawah.

## Ringkasan

| Komponen | Lisensi | Berlaku untuk |
|---|---|---|
| Kode proyek (Ruby, CSS, JS, Liquid, test) | MIT — lihat [LICENSE](LICENSE) | Seluruh berkas buatan sendiri |
| Font Arvo | SIL Open Font License 1.1 | `assets/fonts/arvo-700.woff2` |
| Ikon SVG | MIT (bagian dari proyek) | `_includes/icons.html` |
| Foto produk dan pameran | Hak pemilik masing-masing | `assets/img/**` |
| Nama merek | Milik pemegang merek | Teks di seluruh situs |

---

## 1. Kode proyek — MIT

Semua kode yang ditulis untuk proyek ini berlisensi MIT:

- `lib/**/*.rb` — generator katalog, filter, konfigurasi bahasa
- `_plugins/**/*.rb` — adapter Jekyll
- `test/**/*.rb` — test suite Minitest
- `assets/css/site.css`, `assets/js/*.js`
- `_layouts/**`, `_includes/**` (kecuali aset yang disebut di bawah)
- `Rakefile`, `Gemfile`, `_config.yml`, berkas alur kerja GitHub Actions

Bebas dipakai ulang, dimodifikasi, dan didistribusikan sesuai syarat MIT.

## 2. Font Arvo — SIL Open Font License 1.1

- **Berkas:** `assets/fonts/arvo-700.woff2`
- **Perancang:** Anton Koovit
- **Sumber:** [Google Fonts](https://fonts.google.com/specimen/Arvo)
- **Lisensi:** [SIL Open Font License 1.1](https://scripts.sil.org/OFL)

OFL mengizinkan penggunaan, penyalinan, penggabungan, dan distribusi ulang,
termasuk untuk keperluan komersial, selama font tidak dijual secara terpisah
dan berkas turunan tidak memakai nama font aslinya. Font di-host sendiri agar
situs tidak mengirim permintaan ke server pihak ketiga.

## 3. Ikon SVG — MIT

Seluruh ikon di `_includes/icons.html` digambar tangan untuk proyek ini dan
tercakup lisensi MIT proyek. Ikon merek dagang (WhatsApp, Instagram, Facebook,
X) merupakan penggambaran ulang sederhana yang dipakai hanya sebagai penunjuk
tautan; logo dan merek tersebut tetap milik pemiliknya masing-masing.

Ikon-ikon ini menggantikan tiga berkas PNG berukuran total 428 KB pada versi
2021 situs ini.

## 4. Gambar — hak pemilik masing-masing

Berkas di `assets/img/**` berasal dari tugas kuliah tahun 2021. Gambar aslinya
diunduh dari sumber publik dan **hak ciptanya tetap milik pemegang aslinya**.
Daftar URL sumber tersimpan di repositori asal (`link.txt`) dan mencakup antara
lain: Ducati Media House, Wikimedia Commons, GOMA Brisbane, Robb Report,
Speedcafe, Bike Review, Gridoto, dan Otosia.

Gambar-gambar tersebut dipakai **hanya sebagai contoh visual dalam proyek
portofolio non-komersial**. Repositori ini tidak mengklaim kepemilikan atasnya
dan tidak memberikan lisensi apa pun untuk penggunaan ulang. Jika Anda memakai
ulang kode proyek ini, ganti isi `assets/img/**` dengan gambar milik Anda
sendiri.

## 5. Nama merek

"Kawasaki" adalah merek terdaftar milik Kawasaki Heavy Industries, Ltd.
Nama-nama merek dan model lain yang muncul di situs ini adalah milik pemegang
merek masing-masing.

**HTZL Motorcycle Club adalah perusahaan fiktif.** Situs ini dibuat sebagai
karya portofolio dan latihan pengembangan web. Tidak ada hubungan, afiliasi,
sponsor, atau dukungan apa pun dengan produsen sepeda motor mana pun. Seluruh
harga, spesifikasi, stok, dan berita di situs ini adalah data contoh yang
dibuat oleh program (`lib/htzl/catalog.rb`), bukan penawaran sungguhan.
